use std::collections::{BTreeMap, HashMap};
use std::env;
use std::fs::File;
use std::io::{BufRead, BufReader, BufWriter, Write};

#[derive(Clone, Copy)]
struct Point {
    x: f64,
    y: f64,
    z: f64,
}

fn key(point: Point, cell: f64) -> (i64, i64, i64) {
    (
        (point.x / cell).floor() as i64,
        (point.y / cell).floor() as i64,
        (point.z / cell).floor() as i64,
    )
}

fn distance_squared(a: Point, b: Point) -> f64 {
    (a.x - b.x).powi(2) + (a.y - b.y).powi(2) + (a.z - b.z).powi(2)
}

fn has_return(path: &[Point]) -> bool {
    const GAP: usize = 200;
    const RETURN_SQUARED: f64 = 0.09;
    const EXCURSION_SQUARED: f64 = 9.0;
    const CELL: f64 = 0.3;
    let mut prior = HashMap::<(i64, i64, i64), Vec<usize>>::new();
    for current in 0..path.len() {
        if current >= GAP {
            let eligible = current - GAP;
            prior
                .entry(key(path[eligible], CELL))
                .or_default()
                .push(eligible);
        }
        let center = key(path[current], CELL);
        for dx in -1..=1 {
            for dy in -1..=1 {
                for dz in -1..=1 {
                    let Some(candidates) =
                        prior.get(&(center.0 + dx, center.1 + dy, center.2 + dz))
                    else {
                        continue;
                    };
                    for &earlier in candidates {
                        if distance_squared(path[earlier], path[current]) > RETURN_SQUARED {
                            continue;
                        }
                        if path[earlier + 1..current].iter().any(|&middle| {
                            distance_squared(path[earlier], middle) >= EXCURSION_SQUARED
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

fn crossings(path: &[Point], plane: f64) -> usize {
    path.windows(2)
        .filter(|pair| {
            let left = pair[0].x - plane;
            let right = pair[1].x - plane;
            left == 0.0 || left * right < 0.0
        })
        .count()
}

fn section_states(path: &[Point], plane: f64) -> Vec<(i32, f64, f64)> {
    let mut states = Vec::new();
    for pair in path.windows(2) {
        let left = pair[0].x - plane;
        let right = pair[1].x - plane;
        if left == 0.0 || left * right < 0.0 {
            let fraction = if left == 0.0 {
                0.0
            } else {
                -left / (right - left)
            };
            let y = pair[0].y + fraction * (pair[1].y - pair[0].y);
            let z = pair[0].z + fraction * (pair[1].z - pair[0].z);
            let orientation = if pair[1].x > pair[0].x { 1 } else { -1 };
            states.push((orientation, y, z));
        }
    }
    states
}

fn finish(
    seed: usize,
    points: &mut Vec<Point>,
    distribution: &mut BTreeMap<usize, usize>,
    mismatch: &mut Vec<usize>,
    plane_stats: &mut [(usize, usize)],
    crossing_output: &mut BufWriter<File>,
) -> (usize, usize) {
    if seed == 0 {
        return (0, 0);
    }
    let returned = has_return(points);
    let crossing_count = crossings(points, 111.82069301377661);
    *distribution.entry(crossing_count).or_default() += usize::from(returned);
    let multi = crossing_count >= 9;
    if returned != multi {
        mismatch.push(seed);
    }
    if returned {
        let states = section_states(points, 111.82069301377661);
        assert!(states.len() >= 9);
        for (index, &(orientation, y, z)) in states.iter().take(9).enumerate() {
            writeln!(
                crossing_output,
                "{seed}\t{:.17}\t{:.17}\t{}\t{orientation}\t{y:.17}\t{z:.17}",
                points[0].y,
                points[0].z,
                index + 1
            )
            .unwrap();
        }
    }
    for (index, plane) in [110.5, 111.0, 111.5, 111.82069301377661, 112.0, 112.5, 113.0]
        .iter()
        .copied()
        .enumerate()
    {
        let count = crossings(points, plane);
        if returned {
            plane_stats[index].0 = plane_stats[index].0.min(count);
        } else {
            plane_stats[index].1 = plane_stats[index].1.max(count);
        }
    }
    points.clear();
    (usize::from(returned), usize::from(multi))
}

fn main() {
    let output_path = env::args()
        .nth(1)
        .unwrap_or_else(|| "/tmp/return_ensemble_first9.tsv".to_owned());
    let file = File::open("data/path22_neighborhood_0125.tsv").unwrap();
    let mut lines = BufReader::new(file).lines();
    lines.next();
    let mut seed = 0usize;
    let mut points = Vec::new();
    let mut returned = 0usize;
    let mut multi = 0usize;
    let mut distribution = BTreeMap::new();
    let mut mismatch = Vec::new();
    let mut plane_stats = vec![(usize::MAX, 0usize); 7];
    let mut crossing_output = BufWriter::new(File::create(output_path).unwrap());
    writeln!(
        crossing_output,
        "seed_id\tseed_y\tseed_z\tcrossing_id\torientation\ty\tz"
    )
    .unwrap();
    for line in lines {
        let line = line.unwrap();
        let fields = line.split('\t').collect::<Vec<_>>();
        let next_seed = fields[0].parse::<usize>().unwrap();
        if next_seed != seed {
            let counts = finish(
                seed,
                &mut points,
                &mut distribution,
                &mut mismatch,
                &mut plane_stats,
                &mut crossing_output,
            );
            returned += counts.0;
            multi += counts.1;
            seed = next_seed;
        }
        points.push(Point {
            x: fields[4].parse().unwrap(),
            y: fields[5].parse().unwrap(),
            z: fields[6].parse().unwrap(),
        });
    }
    let counts = finish(
        seed,
        &mut points,
        &mut distribution,
        &mut mismatch,
        &mut plane_stats,
        &mut crossing_output,
    );
    returned += counts.0;
    multi += counts.1;
    crossing_output.flush().unwrap();
    println!("frozen_returns={returned}");
    println!("at_least_nine_crossings={multi}");
    println!("set_mismatches={} ids={mismatch:?}", mismatch.len());
    for (crossing_count, seeds) in distribution {
        println!("returned_crossings={crossing_count} seeds={seeds}");
    }
    for (plane, (minimum_return, maximum_nonreturn)) in
        [110.5, 111.0, 111.5, 111.82069301377661, 112.0, 112.5, 113.0]
            .iter()
            .copied()
            .zip(plane_stats)
    {
        println!(
            "plane_x={plane:.9} minimum_return_crossings={minimum_return} maximum_nonreturn_crossings={maximum_nonreturn} gap={}",
            minimum_return.saturating_sub(maximum_nonreturn)
        );
    }
}
