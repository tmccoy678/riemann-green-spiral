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

#[derive(Clone, Debug)]
struct SpectrumRow {
    start: usize,
    end: usize,
    transitions: usize,
    rmse: f64,
    trace: f64,
    determinant: f64,
    fixed_point: Point,
    matrix: [f64; 9],
    offset: [f64; 3],
    spiral_real: f64,
    spiral_imag: f64,
    spiral_magnitude: f64,
    spiral_log_magnitude: f64,
    spiral_angle: f64,
    spiral_vertical_participation: f64,
    vertical_real: f64,
    vertical_magnitude: f64,
    vertical_log_magnitude: f64,
    vertical_participation: f64,
    rotation_period: f64,
    rotations_in_segment: f64,
    plane_log_total: f64,
    vertical_log_total: f64,
    net_log_total: f64,
}

#[derive(Clone, Copy, Debug)]
struct ComplexValue {
    real: f64,
    imag: f64,
}

impl ComplexValue {
    fn add(self, right: Self) -> Self {
        Self {
            real: self.real + right.real,
            imag: self.imag + right.imag,
        }
    }

    fn scale(self, factor: f64) -> Self {
        Self {
            real: self.real * factor,
            imag: self.imag * factor,
        }
    }

    fn multiply(self, right: Self) -> Self {
        Self {
            real: self.real * right.real - self.imag * right.imag,
            imag: self.real * right.imag + self.imag * right.real,
        }
    }

    fn magnitude(self) -> f64 {
        self.real.hypot(self.imag)
    }
}

#[derive(Clone, Copy, Debug)]
struct PoincareCrossing {
    from_sample: usize,
    orientation: i32,
    point: Point,
}

#[derive(Clone, Debug)]
struct FieldZero {
    id: usize,
    point: Point,
    residual: f64,
    cell: [usize; 3],
    bounds: FieldBounds,
    local: Point,
    spiral: bool,
    nearest_path_distance: f64,
    nearest_path_sample: usize,
    jacobian: [f64; 9],
    eigenvalues: [ComplexValue; 3],
    corners: [[f64; 3]; 8],
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

fn scaled(value: f64, scale: f64) -> i64 {
    (value * scale).round() as i64
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

fn read_spectrum(path: &Path) -> Result<BTreeMap<String, SpectrumRow>, String> {
    let text = fs::read_to_string(path).map_err(|error| format!("{}: {error}", path.display()))?;
    let mut lines = text.lines();
    let header = lines
        .next()
        .ok_or_else(|| format!("{}: empty file", path.display()))?;
    let expected = "segment\tstart\tend\ttransitions\trmse\ttrace\tdeterminant\tcondition\tfixed_x\tfixed_y\tfixed_z\ta11\ta12\ta13\ta21\ta22\ta23\ta31\ta32\ta33\tc1\tc2\tc3\tspiral_real\tspiral_imag\tspiral_magnitude\tspiral_log_magnitude\tspiral_angle\tspiral_vertical_participation\tvertical_real\tvertical_magnitude\tvertical_log_magnitude\tvertical_participation\trotation_period\trotations_in_segment\tplane_log_total\tvertical_log_total\tnet_log_total";
    if header != expected {
        return Err(format!("{}: unexpected header {header:?}", path.display()));
    }
    let mut rows = BTreeMap::new();
    for (offset, line) in lines.enumerate() {
        let context = format!("{}:{}", path.display(), offset + 2);
        let fields = split_exact(line, 38, &context)?;
        let values = fields[4..]
            .iter()
            .map(|value| finite(value, &context))
            .collect::<Result<Vec<_>, _>>()?;
        let start = positive_usize(fields[1], &context)?;
        let end = positive_usize(fields[2], &context)?;
        let transitions = positive_usize(fields[3], &context)?;
        if end <= start || transitions != end - start {
            return Err(format!("{context}: inconsistent segment range"));
        }
        let row = SpectrumRow {
            start,
            end,
            transitions,
            rmse: values[0],
            trace: values[1],
            determinant: values[2],
            fixed_point: Point {
                x: values[4],
                y: values[5],
                z: values[6],
            },
            matrix: values[7..16].try_into().expect("nine matrix values"),
            offset: values[16..19].try_into().expect("three offset values"),
            spiral_real: values[19],
            spiral_imag: values[20],
            spiral_magnitude: values[21],
            spiral_log_magnitude: values[22],
            spiral_angle: values[23],
            spiral_vertical_participation: values[24],
            vertical_real: values[25],
            vertical_magnitude: values[26],
            vertical_log_magnitude: values[27],
            vertical_participation: values[28],
            rotation_period: values[29],
            rotations_in_segment: values[30],
            plane_log_total: values[31],
            vertical_log_total: values[32],
            net_log_total: values[33],
        };
        if rows.insert(fields[0].to_owned(), row).is_some() {
            return Err(format!("{context}: duplicate segment {}", fields[0]));
        }
    }
    if rows.len() != 5 {
        return Err(format!(
            "spectral segment cardinality mismatch: {}",
            rows.len()
        ));
    }
    Ok(rows)
}

fn read_poincare(path: &Path) -> Result<Vec<PoincareCrossing>, String> {
    let text = fs::read_to_string(path).map_err(|error| format!("{}: {error}", path.display()))?;
    let mut lines = text.lines();
    let header = lines
        .next()
        .ok_or_else(|| format!("{}: empty file", path.display()))?;
    if header != "crossing_id\tfrom_sample\torientation\tx\ty\tz" {
        return Err(format!("{}: unexpected header {header:?}", path.display()));
    }
    let mut crossings = Vec::new();
    for (offset, line) in lines.enumerate() {
        let context = format!("{}:{}", path.display(), offset + 2);
        let fields = split_exact(line, 6, &context)?;
        let crossing_id = positive_usize(fields[0], &context)?;
        if crossing_id != crossings.len() + 1 {
            return Err(format!("{context}: reordered crossing id"));
        }
        let orientation = fields[2]
            .parse::<i32>()
            .map_err(|error| format!("{context}: invalid orientation: {error}"))?;
        if ![-1, 1].contains(&orientation) {
            return Err(format!("{context}: orientation must be -1 or 1"));
        }
        crossings.push(PoincareCrossing {
            from_sample: positive_usize(fields[1], &context)?,
            orientation,
            point: Point {
                x: finite(fields[3], &context)?,
                y: finite(fields[4], &context)?,
                z: finite(fields[5], &context)?,
            },
        });
    }
    if crossings.len() != 16 {
        return Err(format!(
            "Poincare crossing cardinality mismatch: {}",
            crossings.len()
        ));
    }
    Ok(crossings)
}

fn read_field_zeros(path: &Path) -> Result<Vec<FieldZero>, String> {
    let text = fs::read_to_string(path).map_err(|error| format!("{}: {error}", path.display()))?;
    let mut lines = text.lines();
    let header = lines
        .next()
        .ok_or_else(|| format!("{}: empty file", path.display()))?;
    let expected = "zero_id\tx\ty\tz\tresidual\tcell_ix\tcell_iy\tcell_iz\tx0\tx1\ty0\ty1\tz0\tz1\ttx\tty\ttz\tspiral\tnearest_path_distance\tnearest_path_sample\tj11\tj12\tj13\tj21\tj22\tj23\tj31\tj32\tj33\te1_real\te1_imag\te2_real\te2_imag\te3_real\te3_imag\tu000\tv000\tw000\tu100\tv100\tw100\tu010\tv010\tw010\tu110\tv110\tw110\tu001\tv001\tw001\tu101\tv101\tw101\tu011\tv011\tw011\tu111\tv111\tw111";
    if header != expected {
        return Err(format!("{}: unexpected header {header:?}", path.display()));
    }

    let mut zeros = Vec::new();
    for (offset, line) in lines.enumerate() {
        let context = format!("{}:{}", path.display(), offset + 2);
        let fields = split_exact(line, 59, &context)?;
        let id = positive_usize(fields[0], &context)?;
        if id != zeros.len() + 1 {
            return Err(format!("{context}: reordered zero id"));
        }
        let spiral = match fields[17] {
            "0" => false,
            "1" => true,
            value => return Err(format!("{context}: invalid spiral flag {value:?}")),
        };
        let values = fields[1..]
            .iter()
            .enumerate()
            .map(|(index, value)| {
                if [4, 5, 6, 18].contains(&index) {
                    Ok(0.0)
                } else {
                    finite(value, &context)
                }
            })
            .collect::<Result<Vec<_>, _>>()?;
        let mut corners = [[0.0; 3]; 8];
        for (corner, values) in corners.iter_mut().zip(fields[35..].chunks_exact(3)) {
            for (target, source) in corner.iter_mut().zip(values) {
                *target = finite(source, &context)?;
            }
        }
        zeros.push(FieldZero {
            id,
            point: Point {
                x: values[0],
                y: values[1],
                z: values[2],
            },
            residual: values[3],
            cell: [
                positive_usize(fields[5], &context)?,
                positive_usize(fields[6], &context)?,
                positive_usize(fields[7], &context)?,
            ],
            bounds: FieldBounds {
                minimum: Point {
                    x: values[7],
                    y: values[9],
                    z: values[11],
                },
                maximum: Point {
                    x: values[8],
                    y: values[10],
                    z: values[12],
                },
            },
            local: Point {
                x: values[13],
                y: values[14],
                z: values[15],
            },
            spiral,
            nearest_path_distance: values[17],
            nearest_path_sample: positive_usize(fields[19], &context)?,
            jacobian: values[19..28].try_into().expect("nine Jacobian values"),
            eigenvalues: [
                ComplexValue {
                    real: values[28],
                    imag: values[29],
                },
                ComplexValue {
                    real: values[30],
                    imag: values[31],
                },
                ComplexValue {
                    real: values[32],
                    imag: values[33],
                },
            ],
            corners,
        });
    }
    if zeros.len() != 19 {
        return Err(format!("field-zero cardinality mismatch: {}", zeros.len()));
    }
    Ok(zeros)
}

fn trilinear_vector(zero: &FieldZero) -> [f64; 3] {
    let t = [zero.local.x, zero.local.y, zero.local.z];
    let mut vector = [0.0; 3];
    for dz in 0..=1 {
        for dy in 0..=1 {
            for dx in 0..=1 {
                let corner = dz * 4 + dy * 2 + dx;
                let weight = if dx == 1 { t[0] } else { 1.0 - t[0] }
                    * if dy == 1 { t[1] } else { 1.0 - t[1] }
                    * if dz == 1 { t[2] } else { 1.0 - t[2] };
                for (target, value) in vector.iter_mut().zip(zero.corners[corner]) {
                    *target += weight * value;
                }
            }
        }
    }
    vector
}

fn trilinear_jacobian(zero: &FieldZero) -> [f64; 9] {
    let t = [zero.local.x, zero.local.y, zero.local.z];
    let widths = [
        zero.bounds.maximum.x - zero.bounds.minimum.x,
        zero.bounds.maximum.y - zero.bounds.minimum.y,
        zero.bounds.maximum.z - zero.bounds.minimum.z,
    ];
    let mut matrix = [0.0; 9];

    for dz in 0..=1 {
        for dy in 0..=1 {
            let weight = (if dy == 1 { t[1] } else { 1.0 - t[1] })
                * (if dz == 1 { t[2] } else { 1.0 - t[2] });
            let low = dz * 4 + dy * 2;
            for component in 0..3 {
                matrix[component * 3] +=
                    (zero.corners[low + 1][component] - zero.corners[low][component]) * weight
                        / widths[0];
            }
        }
    }
    for dz in 0..=1 {
        for dx in 0..=1 {
            let weight = (if dx == 1 { t[0] } else { 1.0 - t[0] })
                * (if dz == 1 { t[2] } else { 1.0 - t[2] });
            let low = dz * 4 + dx;
            for component in 0..3 {
                matrix[component * 3 + 1] +=
                    (zero.corners[low + 2][component] - zero.corners[low][component]) * weight
                        / widths[1];
            }
        }
    }
    for dy in 0..=1 {
        for dx in 0..=1 {
            let weight = (if dx == 1 { t[0] } else { 1.0 - t[0] })
                * (if dy == 1 { t[1] } else { 1.0 - t[1] });
            let low = dy * 2 + dx;
            for component in 0..3 {
                matrix[component * 3 + 2] +=
                    (zero.corners[low + 4][component] - zero.corners[low][component]) * weight
                        / widths[2];
            }
        }
    }
    matrix
}

fn verify_field_zeros(
    zeros: &[FieldZero],
    path22: &[Point],
    field: FieldBounds,
) -> Result<(), String> {
    let mut spiral_count = 0usize;
    for zero in zeros {
        if !field.contains(zero.point) || !zero.bounds.contains(zero.point) {
            return Err(format!(
                "zero {}: point lies outside its measured cell",
                zero.id
            ));
        }
        let widths = [
            zero.bounds.maximum.x - zero.bounds.minimum.x,
            zero.bounds.maximum.y - zero.bounds.minimum.y,
            zero.bounds.maximum.z - zero.bounds.minimum.z,
        ];
        if widths.iter().any(|width| *width <= 0.0) {
            return Err(format!("zero {}: invalid cell bounds", zero.id));
        }
        let local = [
            (zero.point.x - zero.bounds.minimum.x) / widths[0],
            (zero.point.y - zero.bounds.minimum.y) / widths[1],
            (zero.point.z - zero.bounds.minimum.z) / widths[2],
        ];
        if local
            .iter()
            .zip([zero.local.x, zero.local.y, zero.local.z])
            .any(|(derived, exported)| (derived - exported).abs() > 1.0e-12)
        {
            return Err(format!("zero {}: local coordinate mismatch", zero.id));
        }

        let vector = trilinear_vector(zero);
        let residual = vector.iter().map(|value| value * value).sum::<f64>().sqrt();
        if residual >= 1.0e-8 || (residual - zero.residual).abs() > 1.0e-12 {
            return Err(format!("zero {}: trilinear residual mismatch", zero.id));
        }
        let jacobian = trilinear_jacobian(zero);
        if jacobian
            .iter()
            .zip(zero.jacobian)
            .any(|(derived, exported)| (derived - exported).abs() > 2.0e-9)
        {
            return Err(format!("zero {}: analytic Jacobian mismatch", zero.id));
        }
        if zero
            .eigenvalues
            .iter()
            .any(|&value| characteristic_residual(&jacobian, value) > 1.0e-8)
        {
            return Err(format!("zero {}: eigenvalue certificate mismatch", zero.id));
        }
        let spiral = zero
            .eigenvalues
            .iter()
            .any(|value| value.imag.abs() > 1.0e-7);
        if spiral != zero.spiral {
            return Err(format!("zero {}: spiral classification mismatch", zero.id));
        }
        spiral_count += usize::from(spiral);

        let (sample, distance_squared) = path22
            .iter()
            .enumerate()
            .map(|(index, &point)| (index + 1, squared_distance(zero.point, point)))
            .min_by(|left, right| left.1.total_cmp(&right.1))
            .ok_or_else(|| "path 22 is empty".to_owned())?;
        if sample != zero.nearest_path_sample
            || (distance_squared.sqrt() - zero.nearest_path_distance).abs() > 1.0e-11
        {
            return Err(format!(
                "zero {}: nearest-path certificate mismatch",
                zero.id
            ));
        }
    }
    require_equal(spiral_count, 9, "spiral-zero count")?;
    let nearest = zeros
        .iter()
        .min_by(|left, right| {
            left.nearest_path_distance
                .total_cmp(&right.nearest_path_distance)
        })
        .ok_or_else(|| "zero atlas is empty".to_owned())?;
    let nearest_spiral = zeros
        .iter()
        .filter(|zero| zero.spiral)
        .min_by(|left, right| {
            left.nearest_path_distance
                .total_cmp(&right.nearest_path_distance)
        })
        .ok_or_else(|| "spiral-zero atlas is empty".to_owned())?;
    require_equal(nearest.id, 8, "nearest field-zero id")?;
    require_equal(nearest_spiral.id, 3, "nearest spiral-zero id")?;
    require_equal(
        micro(nearest.nearest_path_distance),
        3_243_097,
        "nearest field-zero distance",
    )?;
    require_equal(
        micro(nearest_spiral.nearest_path_distance),
        8_252_508,
        "nearest spiral-zero distance",
    )?;
    Ok(())
}

fn matrix_trace(matrix: &[f64; 9]) -> f64 {
    matrix[0] + matrix[4] + matrix[8]
}

fn matrix_determinant(matrix: &[f64; 9]) -> f64 {
    matrix[0] * (matrix[4] * matrix[8] - matrix[5] * matrix[7])
        - matrix[1] * (matrix[3] * matrix[8] - matrix[5] * matrix[6])
        + matrix[2] * (matrix[3] * matrix[7] - matrix[4] * matrix[6])
}

fn matrix_second_coefficient(matrix: &[f64; 9]) -> f64 {
    matrix[0] * matrix[4] + matrix[0] * matrix[8] + matrix[4] * matrix[8]
        - matrix[1] * matrix[3]
        - matrix[2] * matrix[6]
        - matrix[5] * matrix[7]
}

fn characteristic_residual(matrix: &[f64; 9], value: ComplexValue) -> f64 {
    let square = value.multiply(value);
    let cube = square.multiply(value);
    cube.add(square.scale(-matrix_trace(matrix)))
        .add(value.scale(matrix_second_coefficient(matrix)))
        .add(ComplexValue {
            real: -matrix_determinant(matrix),
            imag: 0.0,
        })
        .magnitude()
}

fn apply_affine(row: &SpectrumRow, point: Point) -> Point {
    let input = [point.x, point.y, point.z];
    let mut output = [0.0; 3];
    for (target, value) in output.iter_mut().enumerate() {
        *value = row.offset[target];
        for (source, coordinate) in input.iter().enumerate() {
            *value += row.matrix[target * 3 + source] * coordinate;
        }
    }
    Point {
        x: output[0],
        y: output[1],
        z: output[2],
    }
}

fn verify_spectrum(rows: &BTreeMap<String, SpectrumRow>, path22: &[Point]) -> Result<(), String> {
    let expected = [
        ("return_1", 1_176, 1_376),
        ("return_2", 1_376, 1_601),
        ("return_3", 1_601, 1_770),
        ("channel", 1_176, 1_770),
        ("post_channel", 1_770, 2_677),
    ];
    for (name, start, end) in expected {
        let row = rows
            .get(name)
            .ok_or_else(|| format!("missing spectral segment {name}"))?;
        if row.start != start || row.end != end || row.transitions != end - start {
            return Err(format!("{name}: spectral range mismatch"));
        }
        let trace_residual = (row.trace - matrix_trace(&row.matrix)).abs();
        let determinant_residual = (row.determinant - matrix_determinant(&row.matrix)).abs();
        if trace_residual > 1.0e-12 || determinant_residual > 1.0e-12 {
            return Err(format!("{name}: trace or determinant mismatch"));
        }
        let mut squared_error = 0.0;
        for sample in start..end {
            squared_error +=
                squared_distance(apply_affine(row, path22[sample - 1]), path22[sample]);
        }
        let rmse = (squared_error / row.transitions as f64).sqrt();
        if (rmse - row.rmse).abs() > 1.0e-12 {
            return Err(format!("{name}: RMSE mismatch"));
        }
        let spiral = ComplexValue {
            real: row.spiral_real,
            imag: row.spiral_imag,
        };
        if characteristic_residual(&row.matrix, spiral) > 1.0e-10
            || characteristic_residual(
                &row.matrix,
                ComplexValue {
                    real: row.vertical_real,
                    imag: 0.0,
                },
            ) > 1.0e-10
        {
            return Err(format!("{name}: eigenvalue certificate mismatch"));
        }
        let magnitude = spiral.magnitude();
        let angle = row.spiral_imag.atan2(row.spiral_real);
        let period = 2.0 * std::f64::consts::PI / angle.abs();
        let derived = [
            (row.spiral_magnitude, magnitude),
            (row.spiral_log_magnitude, magnitude.ln()),
            (row.spiral_angle, angle),
            (row.vertical_magnitude, row.vertical_real.abs()),
            (row.vertical_log_magnitude, row.vertical_real.abs().ln()),
            (row.rotation_period, period),
            (row.rotations_in_segment, row.transitions as f64 / period),
            (
                row.plane_log_total,
                2.0 * row.transitions as f64 * magnitude.ln(),
            ),
            (
                row.vertical_log_total,
                row.transitions as f64 * row.vertical_real.abs().ln(),
            ),
            (
                row.net_log_total,
                row.transitions as f64 * (2.0 * magnitude.ln() + row.vertical_real.abs().ln()),
            ),
        ];
        if derived
            .into_iter()
            .any(|(observed, recomputed)| (observed - recomputed).abs() > 1.0e-11)
        {
            return Err(format!("{name}: derived spectral metric mismatch"));
        }
        if !(0.0..=1.0).contains(&row.spiral_vertical_participation)
            || !(0.0..=1.0).contains(&row.vertical_participation)
        {
            return Err(format!("{name}: invalid eigenvector participation"));
        }
    }

    let channel = &rows["channel"];
    let certificate = [
        (scaled(channel.spiral_magnitude, 1.0e9), 1_000_336_369),
        (scaled(channel.vertical_magnitude, 1.0e9), 999_248_201),
        (scaled(channel.determinant, 1.0e9), 999_920_547),
        (
            scaled(matrix_second_coefficient(&channel.matrix), 1.0e9),
            2_992_856_527,
        ),
        (scaled(channel.rotations_in_segment, 1.0e6), 7_905_063),
        (scaled(channel.plane_log_total, 1.0e9), 399_539_664),
        (scaled(channel.vertical_log_total, 1.0e9), -446_736_681),
        (scaled(channel.net_log_total, 1.0e9), -47_197_017),
        (scaled(channel.vertical_participation, 1.0e9), 985_681_366),
    ];
    for (observed, expected) in certificate {
        if observed != expected {
            return Err(format!(
                "channel spectral certificate mismatch: {observed} != {expected}"
            ));
        }
    }
    Ok(())
}

fn verify_poincare(crossings: &[PoincareCrossing], section_x: f64) -> Result<(), String> {
    let mut last_sample = 0usize;
    let mut positive_y = f64::NEG_INFINITY;
    let mut negative_y = f64::INFINITY;
    let mut last_z = f64::INFINITY;
    for (index, crossing) in crossings.iter().enumerate() {
        let expected_orientation = if index % 2 == 0 { 1 } else { -1 };
        if crossing.orientation != expected_orientation {
            return Err(format!(
                "crossing {}: orientation does not alternate",
                index + 1
            ));
        }
        if crossing.from_sample <= last_sample || (crossing.point.x - section_x).abs() > 1.0e-9 {
            return Err(format!(
                "crossing {}: ordering or section mismatch",
                index + 1
            ));
        }
        if crossing.point.z >= last_z {
            return Err(format!(
                "crossing {}: z is not strictly descending",
                index + 1
            ));
        }
        if crossing.orientation > 0 {
            if crossing.point.y <= positive_y {
                return Err(format!(
                    "crossing {}: positive branch is not expanding",
                    index + 1
                ));
            }
            positive_y = crossing.point.y;
        } else {
            if crossing.point.y >= negative_y {
                return Err(format!(
                    "crossing {}: negative branch is not expanding",
                    index + 1
                ));
            }
            negative_y = crossing.point.y;
        }
        last_sample = crossing.from_sample;
        last_z = crossing.point.z;
    }
    Ok(())
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
    let field_zeros = read_field_zeros(&root.join("data/wind_field_zeros.tsv"))?;
    verify_field_zeros(&field_zeros, path22, bounds)?;
    let spectrum = read_spectrum(&root.join("data/path22_spectrum.tsv"))?;
    verify_spectrum(&spectrum, path22)?;
    let poincare = read_poincare(&root.join("data/path22_poincare.tsv"))?;
    verify_poincare(&poincare, spectrum["channel"].fixed_point.x)?;
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
    let channel_spectrum = &spectrum["channel"];
    println!(
        "spectrum_rotations={:.12} plane_log={:.12} vertical_log={:.12} net_log={:.12}",
        channel_spectrum.rotations_in_segment,
        channel_spectrum.plane_log_total,
        channel_spectrum.vertical_log_total,
        channel_spectrum.net_log_total
    );
    println!(
        "poincare_crossings={} orientation=alternating z=strictly_descending radial=expanding",
        poincare.len()
    );
    let nearest = &field_zeros[7];
    let nearest_spiral = &field_zeros[2];
    println!(
        "field_zeros={} spiral_zeros={} nearest_id={} nearest_cell={:?} nearest_distance={:.12}",
        field_zeros.len(),
        field_zeros.iter().filter(|zero| zero.spiral).count(),
        nearest.id,
        nearest.cell,
        nearest.nearest_path_distance
    );
    println!(
        "nearest_spiral_id={} nearest_spiral_distance={:.12}",
        nearest_spiral.id, nearest_spiral.nearest_path_distance
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
