use std::collections::{BTreeMap, HashMap};
use std::env;
use std::fs::{self, File};
use std::io::{BufRead, BufReader};
use std::path::{Path, PathBuf};

const EXPECTED_PATHS: usize = 49;
const EXPECTED_POINTS: usize = 14_894;
const EXPECTED_PATH22_POINTS: usize = 2_677;
const CHANNEL_START: usize = 1_176;
const CHANNEL_END: usize = 1_770;
const RETURN_DISTANCE_MICRO_SQUARED: i128 = 90_000_000_000;
const TWO_UNITS_MICRO_SQUARED: i128 = 4_000_000_000_000;
const SPEED_2_8_MICRO_SQUARED: i128 = 7_840_000_000_000;
const EXPECTED_NEIGHBORHOOD_SEEDS: usize = 1_089;
const EXPECTED_NEIGHBORHOOD_POINTS: usize = 963_542;
const EXPECTED_NEIGHBORHOOD_RETURNS: usize = 313;
const EXPECTED_CHANNEL_COUNTS: [usize; 4] = [305, 306, 309, 312];

#[derive(Clone, Copy, Debug)]
struct Point {
    x: f64,
    y: f64,
    z: f64,
}

#[derive(Clone, Copy, Debug)]
struct Vector {
    x: f64,
    y: f64,
    z: f64,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
struct MicroPoint(i64, i64, i64);

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
struct MicroVector(i64, i64, i64);

#[derive(Clone, Copy, Debug)]
struct FlowRow {
    point: Point,
    velocity: Vector,
    speed: f64,
}

#[derive(Clone, Debug)]
struct SeedSummary {
    seed_y: f64,
    seed_z: f64,
    length: usize,
    endpoint: Point,
    nearest_boundary: String,
    boundary_gap: f64,
}

#[derive(Debug, Default)]
struct NeighborhoodAudit {
    seeds: usize,
    points: usize,
    returns: usize,
    channel_counts: [usize; 4],
    lower_y_exits: usize,
    return_y_min: f64,
    return_y_max: f64,
    return_z_min: f64,
    return_z_max: f64,
    longest_seed: usize,
    longest_length: usize,
    exterior_samples: usize,
}

#[derive(Clone, Copy, Debug)]
struct FieldBounds {
    minimum: Point,
    maximum: Point,
}

impl FieldBounds {
    fn contains(self, point: Point) -> bool {
        self.minimum.x <= point.x
            && point.x <= self.maximum.x
            && self.minimum.y <= point.y
            && point.y <= self.maximum.y
            && self.minimum.z <= point.z
            && point.z <= self.maximum.z
    }
}

fn finite(text: &str, context: &str) -> Result<f64, String> {
    let value = text
        .parse::<f64>()
        .map_err(|error| format!("{context}: invalid float {text:?}: {error}"))?;
    if value.is_finite() {
        Ok(value)
    } else {
        Err(format!("{context}: non-finite float {text:?}"))
    }
}

fn positive_usize(text: &str, context: &str) -> Result<usize, String> {
    let value = text
        .parse::<usize>()
        .map_err(|error| format!("{context}: invalid integer {text:?}: {error}"))?;
    if value == 0 {
        Err(format!("{context}: expected a one-based positive integer"))
    } else {
        Ok(value)
    }
}

fn micro(value: f64) -> i64 {
    (value * 1_000_000.0).round() as i64
}

fn micro_point(point: Point) -> MicroPoint {
    MicroPoint(micro(point.x), micro(point.y), micro(point.z))
}

fn micro_vector(vector: Vector) -> MicroVector {
    MicroVector(micro(vector.x), micro(vector.y), micro(vector.z))
}

fn squared_distance_micro(left: MicroPoint, right: MicroPoint) -> i128 {
    let dx = i128::from(left.0 - right.0);
    let dy = i128::from(left.1 - right.1);
    let dz = i128::from(left.2 - right.2);
    dx * dx + dy * dy + dz * dz
}

fn squared_magnitude_micro(vector: MicroVector) -> i128 {
    let x = i128::from(vector.0);
    let y = i128::from(vector.1);
    let z = i128::from(vector.2);
    x * x + y * y + z * z
}

fn squared_distance(left: Point, right: Point) -> f64 {
    (left.x - right.x).powi(2) + (left.y - right.y).powi(2) + (left.z - right.z).powi(2)
}

fn split_exact<'a>(line: &'a str, count: usize, context: &str) -> Result<Vec<&'a str>, String> {
    let fields = line.split('\t').collect::<Vec<_>>();
    if fields.len() == count {
        Ok(fields)
    } else {
        Err(format!(
            "{context}: expected {count} tab-separated fields, found {}",
            fields.len()
        ))
    }
}

fn read_paths(path: &Path) -> Result<BTreeMap<usize, Vec<Point>>, String> {
    let text = fs::read_to_string(path).map_err(|error| format!("{}: {error}", path.display()))?;
    let mut lines = text.lines();
    let header = lines
        .next()
        .ok_or_else(|| format!("{}: empty file", path.display()))?;
    if header != "path_id\tpoint_id\tx\ty\tz" {
        return Err(format!("{}: unexpected header {header:?}", path.display()));
    }

    let mut paths = BTreeMap::<usize, Vec<Point>>::new();
    let mut previous_path = 0usize;
    let mut total = 0usize;
    for (offset, line) in lines.enumerate() {
        let line_number = offset + 2;
        let context = format!("{}:{line_number}", path.display());
        let fields = split_exact(line, 5, &context)?;
        let path_id = positive_usize(fields[0], &context)?;
        let point_id = positive_usize(fields[1], &context)?;
        if path_id < previous_path || path_id > previous_path + 1 {
            return Err(format!("{context}: reordered or missing path id {path_id}"));
        }
        previous_path = path_id;
        let points = paths.entry(path_id).or_default();
        if point_id != points.len() + 1 {
            return Err(format!(
                "{context}: expected point {}, found {point_id}",
                points.len() + 1
            ));
        }
        points.push(Point {
            x: finite(fields[2], &context)?,
            y: finite(fields[3], &context)?,
            z: finite(fields[4], &context)?,
        });
        total += 1;
    }
    if paths.len() != EXPECTED_PATHS || total != EXPECTED_POINTS {
        return Err(format!(
            "trajectory cardinality mismatch: paths={} points={total}",
            paths.len()
        ));
    }
    Ok(paths)
}

fn read_flow(path: &Path, path22: &[Point]) -> Result<(Vec<FlowRow>, f64), String> {
    let text = fs::read_to_string(path).map_err(|error| format!("{}: {error}", path.display()))?;
    let mut lines = text.lines();
    let header = lines
        .next()
        .ok_or_else(|| format!("{}: empty file", path.display()))?;
    if header != "point_id\tx\ty\tz\tu\tv\tw\tspeed" {
        return Err(format!("{}: unexpected header {header:?}", path.display()));
    }
    let mut rows = Vec::new();
    let mut max_speed_residual = 0.0_f64;
    for (offset, line) in lines.enumerate() {
        let line_number = offset + 2;
        let context = format!("{}:{line_number}", path.display());
        let fields = split_exact(line, 8, &context)?;
        let point_id = positive_usize(fields[0], &context)?;
        if point_id != rows.len() + 1 {
            return Err(format!(
                "{context}: expected point {}, found {point_id}",
                rows.len() + 1
            ));
        }
        let point = Point {
            x: finite(fields[1], &context)?,
            y: finite(fields[2], &context)?,
            z: finite(fields[3], &context)?,
        };
        let source = path22
            .get(point_id - 1)
            .ok_or_else(|| format!("{context}: flow row exceeds trajectory"))?;
        if point.x.to_bits() != source.x.to_bits()
            || point.y.to_bits() != source.y.to_bits()
            || point.z.to_bits() != source.z.to_bits()
        {
            return Err(format!("{context}: coordinate bits do not match path 22"));
        }
        let velocity = Vector {
            x: finite(fields[4], &context)?,
            y: finite(fields[5], &context)?,
            z: finite(fields[6], &context)?,
        };
        let speed = finite(fields[7], &context)?;
        let recomputed =
            (velocity.x * velocity.x + velocity.y * velocity.y + velocity.z * velocity.z).sqrt();
        let residual = (speed - recomputed).abs();
        max_speed_residual = max_speed_residual.max(residual);
        if residual > 1.0e-12 {
            return Err(format!(
                "{context}: speed residual {residual:.17e} exceeds tolerance"
            ));
        }
        rows.push(FlowRow {
            point,
            velocity,
            speed,
        });
    }
    if rows.len() != EXPECTED_PATH22_POINTS || rows.len() != path22.len() {
        return Err(format!("flow cardinality mismatch: rows={}", rows.len()));
    }
    Ok((rows, max_speed_residual))
}

fn read_meta(path: &Path) -> Result<BTreeMap<String, f64>, String> {
    let text = fs::read_to_string(path).map_err(|error| format!("{}: {error}", path.display()))?;
    let mut lines = text.lines();
    let header = lines
        .next()
        .ok_or_else(|| format!("{}: empty file", path.display()))?;
    if header != "metric\tvalue" {
        return Err(format!("{}: unexpected header {header:?}", path.display()));
    }
    let mut values = BTreeMap::new();
    for (offset, line) in lines.enumerate() {
        let context = format!("{}:{}", path.display(), offset + 2);
        let fields = split_exact(line, 2, &context)?;
        if values
            .insert(fields[0].to_owned(), finite(fields[1], &context)?)
            .is_some()
        {
            return Err(format!("{context}: duplicate metric {}", fields[0]));
        }
    }
    Ok(values)
}

fn meta_value(meta: &BTreeMap<String, f64>, key: &str) -> Result<f64, String> {
    meta.get(key)
        .copied()
        .ok_or_else(|| format!("{key} metadata is missing"))
}

fn field_bounds(meta: &BTreeMap<String, f64>) -> Result<FieldBounds, String> {
    Ok(FieldBounds {
        minimum: Point {
            x: meta_value(meta, "field_x_min")?,
            y: meta_value(meta, "field_y_min")?,
            z: meta_value(meta, "field_z_min")?,
        },
        maximum: Point {
            x: meta_value(meta, "field_x_max")?,
            y: meta_value(meta, "field_y_max")?,
            z: meta_value(meta, "field_z_max")?,
        },
    })
}

fn read_seed_summaries(path: &Path) -> Result<BTreeMap<usize, SeedSummary>, String> {
    let file = File::open(path).map_err(|error| format!("{}: {error}", path.display()))?;
    let mut lines = BufReader::new(file).lines();
    let header = lines
        .next()
        .ok_or_else(|| format!("{}: empty file", path.display()))?
        .map_err(|error| format!("{}: {error}", path.display()))?;
    if header
        != "seed_id\tseed_y\tseed_z\tlength\tend_x\tend_y\tend_z\tnearest_boundary\tboundary_gap"
    {
        return Err(format!("{}: unexpected header {header:?}", path.display()));
    }
    let mut summaries = BTreeMap::new();
    for (offset, line) in lines.enumerate() {
        let line_number = offset + 2;
        let context = format!("{}:{line_number}", path.display());
        let line = line.map_err(|error| format!("{context}: {error}"))?;
        let fields = split_exact(&line, 9, &context)?;
        let seed_id = positive_usize(fields[0], &context)?;
        let summary = SeedSummary {
            seed_y: finite(fields[1], &context)?,
            seed_z: finite(fields[2], &context)?,
            length: positive_usize(fields[3], &context)?,
            endpoint: Point {
                x: finite(fields[4], &context)?,
                y: finite(fields[5], &context)?,
                z: finite(fields[6], &context)?,
            },
            nearest_boundary: fields[7].to_owned(),
            boundary_gap: finite(fields[8], &context)?,
        };
        if summaries.insert(seed_id, summary).is_some() {
            return Err(format!("{context}: duplicate seed id {seed_id}"));
        }
    }
    if summaries.len() != EXPECTED_NEIGHBORHOOD_SEEDS {
        return Err(format!(
            "seed summary cardinality mismatch: {}",
            summaries.len()
        ));
    }
    Ok(summaries)
}

fn cell_key(point: Point, cell: f64) -> (i64, i64, i64) {
    (
        (point.x / cell).floor() as i64,
        (point.y / cell).floor() as i64,
        (point.z / cell).floor() as i64,
    )
}

fn channel_index(channel: &[Point], cell: f64) -> HashMap<(i64, i64, i64), Vec<Point>> {
    let mut index = HashMap::<(i64, i64, i64), Vec<Point>>::new();
    for &point in channel {
        index.entry(cell_key(point, cell)).or_default().push(point);
    }
    index
}

fn minimum_channel_distance_squared(
    path: &[Point],
    index: &HashMap<(i64, i64, i64), Vec<Point>>,
    cell: f64,
) -> f64 {
    let mut minimum = f64::INFINITY;
    for &point in path {
        let key = cell_key(point, cell);
        for dx in -1..=1 {
            for dy in -1..=1 {
                for dz in -1..=1 {
                    if let Some(candidates) = index.get(&(key.0 + dx, key.1 + dy, key.2 + dz)) {
                        for &candidate in candidates {
                            minimum = minimum.min(squared_distance(point, candidate));
                        }
                    }
                }
            }
        }
    }
    minimum
}

fn has_return_witness(path: &[Point]) -> bool {
    const MINIMUM_GAP: usize = 200;
    const RETURN_SQUARED: f64 = 0.09;
    const EXCURSION_SQUARED: f64 = 9.0;
    const CELL: f64 = 0.3;
    let mut prior = HashMap::<(i64, i64, i64), Vec<usize>>::new();
    for current in 0..path.len() {
        if current >= MINIMUM_GAP {
            let eligible = current - MINIMUM_GAP;
            prior
                .entry(cell_key(path[eligible], CELL))
                .or_default()
                .push(eligible);
        }
        let key = cell_key(path[current], CELL);
        for dx in -1..=1 {
            for dy in -1..=1 {
                for dz in -1..=1 {
                    let Some(candidates) = prior.get(&(key.0 + dx, key.1 + dy, key.2 + dz)) else {
                        continue;
                    };
                    for &earlier in candidates {
                        if squared_distance(path[earlier], path[current]) > RETURN_SQUARED {
                            continue;
                        }
                        if path[earlier + 1..current].iter().any(|&middle| {
                            squared_distance(path[earlier], middle) >= EXCURSION_SQUARED
                        }) {
                            return true;
                        }
                    }
                }
            }
        }
    }
    false
}

fn audit_neighborhood(
    path: &Path,
    summaries: &BTreeMap<usize, SeedSummary>,
    path22: &[Point],
    bounds: FieldBounds,
) -> Result<NeighborhoodAudit, String> {
    let file = File::open(path).map_err(|error| format!("{}: {error}", path.display()))?;
    let mut lines = BufReader::new(file).lines();
    let header = lines
        .next()
        .ok_or_else(|| format!("{}: empty file", path.display()))?
        .map_err(|error| format!("{}: {error}", path.display()))?;
    if header != "seed_id\tseed_y\tseed_z\tpoint_id\tx\ty\tz" {
        return Err(format!("{}: unexpected header {header:?}", path.display()));
    }

    let channel = &path22[CHANNEL_START - 1..CHANNEL_END];
    let channel_cell = 2.0;
    let channel_index = channel_index(channel, channel_cell);
    let mut audit = NeighborhoodAudit {
        return_y_min: f64::INFINITY,
        return_y_max: f64::NEG_INFINITY,
        return_z_min: f64::INFINITY,
        return_z_max: f64::NEG_INFINITY,
        ..NeighborhoodAudit::default()
    };
    let mut current_seed = 0usize;
    let mut current_y = 0.0;
    let mut current_z = 0.0;
    let mut points = Vec::<Point>::new();

    let finish_seed = |seed_id: usize,
                       seed_y: f64,
                       seed_z: f64,
                       points: &mut Vec<Point>,
                       audit: &mut NeighborhoodAudit|
     -> Result<(), String> {
        if seed_id == 0 {
            return Ok(());
        }
        let summary = summaries
            .get(&seed_id)
            .ok_or_else(|| format!("missing summary for seed {seed_id}"))?;
        if summary.seed_y.to_bits() != seed_y.to_bits()
            || summary.seed_z.to_bits() != seed_z.to_bits()
            || summary.length != points.len()
        {
            return Err(format!("seed {seed_id}: summary identity mismatch"));
        }
        let endpoint = *points
            .last()
            .ok_or_else(|| format!("seed {seed_id}: empty path"))?;
        if endpoint.x.to_bits() != summary.endpoint.x.to_bits()
            || endpoint.y.to_bits() != summary.endpoint.y.to_bits()
            || endpoint.z.to_bits() != summary.endpoint.z.to_bits()
        {
            return Err(format!("seed {seed_id}: endpoint mismatch"));
        }
        let gap = endpoint.y - bounds.minimum.y;
        if summary.nearest_boundary != "y_min"
            || (summary.boundary_gap - gap).abs() > 1.0e-12
            || !(0.0..0.13).contains(&gap)
        {
            return Err(format!(
                "seed {seed_id}: lower-y boundary certificate mismatch"
            ));
        }
        audit.lower_y_exits += 1;
        let minimum = minimum_channel_distance_squared(points, &channel_index, channel_cell);
        for (index, threshold) in [0.3_f64, 0.5, 1.0, 2.0].into_iter().enumerate() {
            if minimum <= threshold * threshold {
                audit.channel_counts[index] += 1;
            }
        }
        if has_return_witness(points) {
            audit.returns += 1;
            audit.return_y_min = audit.return_y_min.min(seed_y);
            audit.return_y_max = audit.return_y_max.max(seed_y);
            audit.return_z_min = audit.return_z_min.min(seed_z);
            audit.return_z_max = audit.return_z_max.max(seed_z);
        }
        if points.len() > audit.longest_length {
            audit.longest_seed = seed_id;
            audit.longest_length = points.len();
        }
        if seed_id == 545 {
            if seed_y.to_bits() != 20.0_f64.to_bits()
                || seed_z.to_bits() != 6.0_f64.to_bits()
                || points.len() != path22.len()
                || points.iter().zip(path22).any(|(left, right)| {
                    left.x.to_bits() != right.x.to_bits()
                        || left.y.to_bits() != right.y.to_bits()
                        || left.z.to_bits() != right.z.to_bits()
                })
            {
                return Err("center seed does not reproduce path 22".to_owned());
            }
        }
        audit.seeds += 1;
        audit.points += points.len();
        points.clear();
        Ok(())
    };

    for (offset, line) in lines.enumerate() {
        let line_number = offset + 2;
        let context = format!("{}:{line_number}", path.display());
        let line = line.map_err(|error| format!("{context}: {error}"))?;
        let fields = split_exact(&line, 7, &context)?;
        let seed_id = positive_usize(fields[0], &context)?;
        let seed_y = finite(fields[1], &context)?;
        let seed_z = finite(fields[2], &context)?;
        let point_id = positive_usize(fields[3], &context)?;
        if seed_id != current_seed {
            if current_seed != 0 && seed_id != current_seed + 1 {
                return Err(format!("{context}: missing or reordered seed {seed_id}"));
            }
            finish_seed(current_seed, current_y, current_z, &mut points, &mut audit)?;
            current_seed = seed_id;
            current_y = seed_y;
            current_z = seed_z;
        } else if seed_y.to_bits() != current_y.to_bits() || seed_z.to_bits() != current_z.to_bits()
        {
            return Err(format!("{context}: seed coordinates changed within a path"));
        }
        if point_id != points.len() + 1 {
            return Err(format!(
                "{context}: expected point {}, found {point_id}",
                points.len() + 1
            ));
        }
        points.push(Point {
            x: finite(fields[4], &context)?,
            y: finite(fields[5], &context)?,
            z: finite(fields[6], &context)?,
        });
        if !bounds.contains(*points.last().expect("point was just pushed")) {
            return Err(format!(
                "{context}: trajectory sample lies outside measured field"
            ));
        }
    }
    finish_seed(current_seed, current_y, current_z, &mut points, &mut audit)?;

    require_equal(
        audit.seeds,
        EXPECTED_NEIGHBORHOOD_SEEDS,
        "neighborhood seed count",
    )?;
    require_equal(
        audit.points,
        EXPECTED_NEIGHBORHOOD_POINTS,
        "neighborhood point count",
    )?;
    require_equal(
        audit.returns,
        EXPECTED_NEIGHBORHOOD_RETURNS,
        "neighborhood return count",
    )?;
    require_equal(
        audit.channel_counts,
        EXPECTED_CHANNEL_COUNTS,
        "neighborhood channel counts",
    )?;
    require_equal(
        audit.lower_y_exits,
        EXPECTED_NEIGHBORHOOD_SEEDS,
        "lower-y exit count",
    )?;
    Ok(audit)
}

fn require_equal<T: std::fmt::Debug + PartialEq>(
    observed: T,
    expected: T,
    label: &str,
) -> Result<(), String> {
    if observed == expected {
        Ok(())
    } else {
        Err(format!(
            "{label}: observed {observed:?}, expected {expected:?}"
        ))
    }
}

fn run(root: &Path) -> Result<(), String> {
    let paths = read_paths(&root.join("data/riemann_paths.tsv"))?;
    let path22 = paths
        .get(&22)
        .ok_or_else(|| "path 22 is missing".to_owned())?;
    require_equal(path22.len(), EXPECTED_PATH22_POINTS, "path-22 length")?;
    let (flow, max_speed_residual) = read_flow(&root.join("data/path22_flow.tsv"), path22)?;
    let meta = read_meta(&root.join("data/path22_field_meta.tsv"))?;
    let bounds = field_bounds(&meta)?;
    if paths
        .values()
        .flat_map(|path| path.iter())
        .any(|&point| !bounds.contains(point))
    {
        return Err(
            "a preserved source trajectory sample lies outside the measured field".to_owned(),
        );
    }

    let witness_points = [
        (1_176, MicroPoint(110_196_112, 23_287_421, 4_400_549)),
        (1_376, MicroPoint(110_067_375, 23_297_624, 4_170_377)),
        (1_601, MicroPoint(109_923_256, 23_291_677, 3_947_771)),
        (1_770, MicroPoint(109_743_260, 23_359_119, 3_803_687)),
    ];
    for (sample, expected) in witness_points {
        require_equal(
            micro_point(path22[sample - 1]),
            expected,
            &format!("path-22 sample {sample}"),
        )?;
    }
    for (left, right) in [(1_176, 1_376), (1_376, 1_601), (1_601, 1_770)] {
        let distance = squared_distance_micro(
            micro_point(path22[left - 1]),
            micro_point(path22[right - 1]),
        );
        if distance > RETURN_DISTANCE_MICRO_SQUARED {
            return Err(format!("return {left}->{right} exceeds the 0.3-unit bound"));
        }
    }

    let (minimum_z_offset, minimum_z_point) = path22
        .iter()
        .enumerate()
        .min_by(|left, right| left.1.z.total_cmp(&right.1.z))
        .ok_or_else(|| "path 22 is empty".to_owned())?;
    require_equal(minimum_z_offset + 1, 2_605, "recorded minimum-z sample")?;
    require_equal(micro(minimum_z_point.z), 3_361_277, "recorded minimum z")?;
    if path22.iter().any(|point| point.z < 3.3) {
        return Err("a path-22 sample falls below z = 3.3".to_owned());
    }

    let endpoint = path22[path22.len() - 1];
    require_equal(
        micro_point(endpoint),
        MicroPoint(115_073_580, 17_552_947, 3_361_768),
        "path-22 endpoint",
    )?;
    let field_y_min = bounds.minimum.y;
    let boundary_gap = endpoint.y - field_y_min;
    if !(0.0..0.06).contains(&boundary_gap) {
        return Err(format!(
            "endpoint boundary gap {boundary_gap} is outside [0, 0.06)"
        ));
    }

    let corridor = &flow[CHANNEL_START - 1..CHANNEL_END];
    let (corridor_minimum_offset, corridor_minimum) = corridor
        .iter()
        .enumerate()
        .min_by(|left, right| left.1.speed.total_cmp(&right.1.speed))
        .ok_or_else(|| "return corridor is empty".to_owned())?;
    require_equal(
        CHANNEL_START + corridor_minimum_offset,
        1_230,
        "corridor minimum-speed sample",
    )?;
    require_equal(
        micro_vector(corridor_minimum.velocity),
        MicroVector(-1_886_341, 2_128_249, -31_635),
        "corridor minimum-speed vector",
    )?;
    if corridor.iter().any(|row| row.speed < 2.8) {
        return Err("the sampled corridor contains speed below 2.8".to_owned());
    }
    if squared_magnitude_micro(micro_vector(corridor_minimum.velocity)) < SPEED_2_8_MICRO_SQUARED {
        return Err("the quantized corridor certificate is below 2.8".to_owned());
    }

    let mut closest = (f64::INFINITY, 0usize, 0usize, 0usize);
    for (&path_id, points) in &paths {
        if path_id == 22 {
            continue;
        }
        for (point_offset, &point) in points.iter().enumerate() {
            for (channel_offset, row) in corridor.iter().enumerate() {
                let distance = squared_distance(point, row.point);
                if distance < closest.0 {
                    closest = (
                        distance,
                        path_id,
                        point_offset + 1,
                        CHANNEL_START + channel_offset,
                    );
                }
            }
        }
    }
    if closest.0 <= 4.0 {
        return Err(format!(
            "another path enters the two-unit channel: {closest:?}"
        ));
    }
    require_equal(
        (closest.1, closest.2, closest.3),
        (29, 207, 1_191),
        "closest other-path certificate",
    )?;
    let closest_other = micro_point(paths[&29][206]);
    let closest_channel = micro_point(path22[1_190]);
    require_equal(
        closest_other,
        MicroPoint(111_440_711, 26_424_889, 7_967_842),
        "closest path-29 point",
    )?;
    require_equal(
        closest_channel,
        MicroPoint(111_637_323, 24_892_345, 4_375_207),
        "closest path-22 channel point",
    )?;
    if squared_distance_micro(closest_other, closest_channel) <= TWO_UNITS_MICRO_SQUARED {
        return Err("closest quantized certificate is not above two units".to_owned());
    }

    let summaries = read_seed_summaries(&root.join("data/path22_neighborhood_seeds.tsv"))?;
    let neighborhood = audit_neighborhood(
        &root.join("data/path22_neighborhood_0125.tsv"),
        &summaries,
        path22,
        bounds,
    )?;
    let post_channel_arc = path22[CHANNEL_END - 1..]
        .windows(2)
        .map(|window| squared_distance(window[0], window[1]).sqrt())
        .sum::<f64>();

    println!("PATH22_CHANNEL_AUDIT_VERIFIED");
    println!("paths={} points={EXPECTED_POINTS}", paths.len());
    println!("channel={CHANNEL_START}..={CHANNEL_END}");
    println!(
        "corridor_min_speed_sample={} speed={:.12}",
        CHANNEL_START + corridor_minimum_offset,
        corridor_minimum.speed
    );
    println!(
        "closest_other_path={} point={} channel_point={} distance={:.12}",
        closest.1,
        closest.2,
        closest.3,
        closest.0.sqrt()
    );
    println!("minimum_z_sample=2605 z={:.12}", minimum_z_point.z);
    println!("boundary_gap={boundary_gap:.12}");
    println!("max_speed_residual={max_speed_residual:.17e}");
    println!(
        "neighborhood_seeds={} points={} returns={}",
        neighborhood.seeds, neighborhood.points, neighborhood.returns
    );
    println!(
        "channel_counts_0.3_0.5_1_2={:?}",
        neighborhood.channel_counts
    );
    println!(
        "return_seed_range_y={:.3}..={:.3} z={:.3}..={:.3}",
        neighborhood.return_y_min,
        neighborhood.return_y_max,
        neighborhood.return_z_min,
        neighborhood.return_z_max
    );
    println!(
        "lower_y_exits={} longest_seed={} longest_length={}",
        neighborhood.lower_y_exits, neighborhood.longest_seed, neighborhood.longest_length
    );
    println!(
        "path22_after_channel_samples={} arc={post_channel_arc:.12} outcome=unresolved_after_boundary",
        path22.len() - CHANNEL_END
    );
    println!(
        "boundary_assumptions=none exterior_samples={} exterior_velocity=unassigned",
        neighborhood.exterior_samples
    );
    Ok(())
}

fn main() {
    let root = env::args_os()
        .nth(1)
        .map(PathBuf::from)
        .unwrap_or_else(|| Path::new(env!("CARGO_MANIFEST_DIR")).join("../.."));
    if let Err(error) = run(&root) {
        eprintln!("PATH22_CHANNEL_AUDIT_FAILED: {error}");
        std::process::exit(1);
    }
}
