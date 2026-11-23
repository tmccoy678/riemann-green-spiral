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

fn key(p: Point, cell: f64) -> (i64, i64, i64) {
    (
        (p.x / cell).floor() as i64,
        (p.y / cell).floor() as i64,
        (p.z / cell).floor() as i64,
    )
}
fn d2(a: Point, b: Point) -> f64 {
    (a.x - b.x).powi(2) + (a.y - b.y).powi(2) + (a.z - b.z).powi(2)
}
fn has_return(path: &[Point]) -> bool {
    let mut prior = HashMap::<(i64, i64, i64), Vec<usize>>::new();
    for current in 0..path.len() {
        if current >= 200 {
            let eligible = current - 200;
            prior
                .entry(key(path[eligible], 0.3))
                .or_default()
                .push(eligible);
        }
        let center = key(path[current], 0.3);
        for dx in -1..=1 {
            for dy in -1..=1 {
                for dz in -1..=1 {
                    let Some(candidates) =
                        prior.get(&(center.0 + dx, center.1 + dy, center.2 + dz))
                    else {
                        continue;
                    };
                    for &earlier in candidates {
                        if d2(path[earlier], path[current]) > 0.09 {
                            continue;
                        }
                        if path[earlier + 1..current]
                            .iter()
                            .any(|&middle| d2(path[earlier], middle) >= 9.0)
                        {
                            return true;
                        }
                    }
                }
            }
        }
    }
    false
}
fn section(path: &[Point], plane: f64) -> Vec<i32> {
    path.windows(2)
        .filter_map(|pair| {
            let left = pair[0].x - plane;
            let right = pair[1].x - plane;
            if left == 0.0 || left * right < 0.0 {
                Some(if pair[1].x > pair[0].x { 1 } else { -1 })
            } else {
                None
            }
        })
        .collect()
}
fn finish(
    seed: usize,
    sy: f64,
    sz: f64,
    path: &mut Vec<Point>,
    distribution: &mut BTreeMap<usize, usize>,
    writer: &mut BufWriter<File>,
    mismatches: &mut Vec<usize>,
) -> (usize, usize) {
    if seed == 0 {
        return (0, 0);
    }
    let returned = has_return(path);
    let orientations = section(path, 111.82069301377661);
    let count = orientations.len();
    *distribution.entry(count).or_default() += 1;
    let classified = count >= 9;
    if returned != classified {
        mismatches.push(seed)
    }
    let alternating = orientations
        .iter()
        .take(9)
        .enumerate()
        .all(|(i, &o)| o == if i % 2 == 0 { 1 } else { -1 });
    writeln!(
        writer,
        "{seed}\t{sy:.17}\t{sz:.17}\t{}\t{count}\t{}",
        usize::from(returned),
        usize::from(alternating)
    )
    .unwrap();
    path.clear();
    (usize::from(returned), usize::from(classified))
}
fn main() {
    let input = env::args()
        .nth(1)
        .unwrap_or_else(|| "/tmp/return_boundary_refinement.tsv".into());
    let output = env::args()
        .nth(2)
        .unwrap_or_else(|| "/tmp/return_boundary_refinement_summary.tsv".into());
    let file = File::open(input).unwrap();
    let mut lines = BufReader::new(file).lines();
    lines.next();
    let mut writer = BufWriter::new(File::create(output).unwrap());
    writeln!(
        writer,
        "seed_id\tseed_y\tseed_z\treturned\tcrossings\tfirst_nine_alternating"
    )
    .unwrap();
    let mut seed = 0usize;
    let mut sy = 0.0;
    let mut sz = 0.0;
    let mut path = Vec::new();
    let mut distribution = BTreeMap::new();
    let mut mismatches = Vec::new();
    let mut returns = 0;
    let mut classified = 0;
    for line in lines {
        let line = line.unwrap();
        let f = line.split('\t').collect::<Vec<_>>();
        let next = f[0].parse::<usize>().unwrap();
        if next != seed {
            let c = finish(
                seed,
                sy,
                sz,
                &mut path,
                &mut distribution,
                &mut writer,
                &mut mismatches,
            );
            returns += c.0;
            classified += c.1;
            seed = next;
            sy = f[1].parse().unwrap();
            sz = f[2].parse().unwrap();
        }
        path.push(Point {
            x: f[4].parse().unwrap(),
            y: f[5].parse().unwrap(),
            z: f[6].parse().unwrap(),
        });
    }
    let c = finish(
        seed,
        sy,
        sz,
        &mut path,
        &mut distribution,
        &mut writer,
        &mut mismatches,
    );
    returns += c.0;
    classified += c.1;
    writer.flush().unwrap();
    println!("refined_seeds={} returns={returns} crossings_at_least_9={classified} mismatches={} ids={mismatches:?}",distribution.values().sum::<usize>(),mismatches.len());
    for (k, v) in distribution {
        println!("crossings={k} seeds={v}")
    }
}
