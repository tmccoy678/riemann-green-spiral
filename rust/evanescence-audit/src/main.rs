use std::env;
use std::fs;
use std::path::{Path, PathBuf};

#[derive(Clone, Debug)]
struct Ray {
    cycle: usize,
    ray_id: usize,
    ray: String,
    kappa: f64,
    exponential_r2: f64,
    gaussian_q: f64,
    gaussian_r2: f64,
    monotonic_fraction: f64,
    mean_alignment: f64,
    minimum_alignment: f64,
    evanescent: bool,
}

#[derive(Clone, Copy, Debug)]
struct Width {
    cycle: usize,
    arc: f64,
    gaussian_q: f64,
    width_squared: f64,
    prediction: f64,
}

fn finite(text: &str, context: &str) -> Result<f64, String> {
    let value = text
        .parse::<f64>()
        .map_err(|error| format!("{context}: invalid float {text:?}: {error}"))?;
    value
        .is_finite()
        .then_some(value)
        .ok_or_else(|| format!("{context}: non-finite float"))
}

fn positive_usize(text: &str, context: &str) -> Result<usize, String> {
    let value = text
        .parse::<usize>()
        .map_err(|error| format!("{context}: invalid integer: {error}"))?;
    (value > 0)
        .then_some(value)
        .ok_or_else(|| format!("{context}: expected positive integer"))
}

fn split_exact<'a>(line: &'a str, count: usize, context: &str) -> Result<Vec<&'a str>, String> {
    let fields = line.split('\t').collect::<Vec<_>>();
    let found = fields.len();
    (found == count)
        .then_some(fields)
        .ok_or_else(|| format!("{context}: expected {count} fields, found {found}"))
}

fn read_rays(path: &Path) -> Result<Vec<Ray>, String> {
    let text = fs::read_to_string(path).map_err(|error| format!("{}: {error}", path.display()))?;
    let mut lines = text.lines();
    let header = lines.next().ok_or_else(|| "empty ray table".to_owned())?;
    let expected = "cycle\tray_id\tray\tkappa\texponential_r2\tgaussian_q\tgaussian_r2\tmonotonic_fraction\tmean_tangential_alignment\tminimum_tangential_alignment\tevanescent_local";
    if header != expected {
        return Err("unexpected ray header".to_owned());
    }
    let mut rows = Vec::new();
    for (offset, line) in lines.enumerate() {
        let context = format!("{}:{}", path.display(), offset + 2);
        let f = split_exact(line, 11, &context)?;
        let evanescent = match f[10] {
            "0" => false,
            "1" => true,
            _ => return Err(format!("{context}: invalid evanescence flag")),
        };
        rows.push(Ray {
            cycle: positive_usize(f[0], &context)?,
            ray_id: positive_usize(f[1], &context)?,
            ray: f[2].to_owned(),
            kappa: finite(f[3], &context)?,
            exponential_r2: finite(f[4], &context)?,
            gaussian_q: finite(f[5], &context)?,
            gaussian_r2: finite(f[6], &context)?,
            monotonic_fraction: finite(f[7], &context)?,
            mean_alignment: finite(f[8], &context)?,
            minimum_alignment: finite(f[9], &context)?,
            evanescent,
        });
    }
    (rows.len() == 12)
        .then_some(rows)
        .ok_or_else(|| "ray cardinality mismatch".to_owned())
}

fn read_widths(path: &Path) -> Result<Vec<Width>, String> {
    let text = fs::read_to_string(path).map_err(|error| format!("{}: {error}", path.display()))?;
    let mut lines = text.lines();
    let header = lines.next().ok_or_else(|| "empty width table".to_owned())?;
    if header != "cycle\tarc_from_cycle_7\tgaussian_q\twidth_squared\tlinear_prediction" {
        return Err("unexpected width header".to_owned());
    }
    let mut rows = Vec::new();
    for (offset, line) in lines.enumerate() {
        let context = format!("{}:{}", path.display(), offset + 2);
        let f = split_exact(line, 5, &context)?;
        rows.push(Width {
            cycle: positive_usize(f[0], &context)?,
            arc: finite(f[1], &context)?,
            gaussian_q: finite(f[2], &context)?,
            width_squared: finite(f[3], &context)?,
            prediction: finite(f[4], &context)?,
        });
    }
    (rows.len() == 3)
        .then_some(rows)
        .ok_or_else(|| "width cardinality mismatch".to_owned())
}

fn scaled(value: f64, factor: f64) -> i64 {
    (value * factor).round() as i64
}

fn linear_fit(x: &[f64], y: &[f64]) -> (f64, f64, f64) {
    let count = x.len() as f64;
    let mean_x = x.iter().sum::<f64>() / count;
    let mean_y = y.iter().sum::<f64>() / count;
    let covariance = x
        .iter()
        .zip(y)
        .map(|(x, y)| (x - mean_x) * (y - mean_y))
        .sum::<f64>();
    let variance = x.iter().map(|x| (x - mean_x).powi(2)).sum::<f64>();
    let slope = covariance / variance;
    let intercept = mean_y - slope * mean_x;
    let residual = x
        .iter()
        .zip(y)
        .map(|(x, y)| (y - (slope * x + intercept)).powi(2))
        .sum::<f64>();
    let total = y.iter().map(|y| (y - mean_y).powi(2)).sum::<f64>();
    (slope, intercept, 1.0 - residual / total)
}

fn require_equal<T: std::fmt::Debug + PartialEq>(
    value: T,
    expected: T,
    label: &str,
) -> Result<(), String> {
    (value == expected)
        .then_some(())
        .ok_or_else(|| format!("{label}: observed {value:?}, expected {expected:?}"))
}

fn run(root: &Path) -> Result<(), String> {
    let rays = read_rays(&root.join("data/local_evanescence.tsv"))?;
    for cycle in 7..=9 {
        let cycle_rows = rays
            .iter()
            .filter(|row| row.cycle == cycle)
            .collect::<Vec<_>>();
        require_equal(cycle_rows.len(), 4, "rays per cycle")?;
        for (offset, row) in cycle_rows.iter().enumerate() {
            require_equal(row.ray_id, offset + 1, "ray ordering")?;
            if !(0.0..=1.0).contains(&row.exponential_r2)
                || !(0.0..=1.0).contains(&row.gaussian_r2)
                || !(0.0..=1.0).contains(&row.monotonic_fraction)
                || !(-1.0..=1.0).contains(&row.mean_alignment)
                || !(-1.0..=1.0).contains(&row.minimum_alignment)
                || row.gaussian_q <= 0.0
            {
                return Err(format!("cycle {cycle}: invalid bounded metric"));
            }
            let criterion = row.kappa > 0.0
                && row.exponential_r2 >= 0.95
                && row.monotonic_fraction >= 0.8
                && row.mean_alignment >= 0.8;
            if criterion != row.evanescent {
                return Err(format!("cycle {cycle}: evanescence criterion mismatch"));
            }
        }
    }

    let selected = rays
        .iter()
        .filter(|row| row.ray == "normal_2_negative")
        .collect::<Vec<_>>();
    require_equal(selected.len(), 3, "selected-side cardinality")?;
    if selected.iter().any(|row| !row.evanescent) {
        return Err("selected side is not evanescent across all cycles".to_owned());
    }

    let widths = read_widths(&root.join("data/gaussian_width_growth.tsv"))?;
    for (index, width) in widths.iter().enumerate() {
        let ray = selected[index];
        require_equal(width.cycle, ray.cycle, "cycle binding")?;
        if (width.gaussian_q - ray.gaussian_q).abs() > 1.0e-14 {
            return Err("Gaussian-q binding mismatch".to_owned());
        }
        let recomputed = 1.0 / (2.0 * ray.gaussian_q);
        if (width.width_squared - recomputed).abs() > 1.0e-12 {
            return Err("Gaussian width mismatch".to_owned());
        }
    }

    let x = widths.iter().map(|row| row.arc).collect::<Vec<_>>();
    let y = widths
        .iter()
        .map(|row| row.width_squared)
        .collect::<Vec<_>>();
    let (slope, intercept, r_squared) = linear_fit(&x, &y);
    for width in &widths {
        if (width.prediction - (slope * width.arc + intercept)).abs() > 1.0e-12 {
            return Err("linear prediction mismatch".to_owned());
        }
    }
    if slope <= 0.0 || r_squared < 0.95 {
        return Err("diffusion-compatibility criterion failed".to_owned());
    }

    let expected_kappa = [667_736_465, 629_305_112, 586_467_384];
    let expected_exp_r2 = [980_568_819, 970_250_982, 963_970_165];
    let expected_gauss_q = [502_666_989, 477_549_973, 446_900_833];
    let expected_gauss_r2 = [982_450_965, 987_828_342, 989_647_322];
    let expected_monotonic = [1_000_000_000, 1_000_000_000, 1_000_000_000];
    let expected_alignment = [844_959_383, 996_155_137, 996_692_395];
    let expected_width = [994_694_322, 1_047_010_843, 1_118_816_441];
    let expected_arc = [0, 12_530_841, 25_914_549];
    for index in 0..3 {
        require_equal(
            scaled(selected[index].kappa, 1.0e9),
            expected_kappa[index],
            "kappa certificate",
        )?;
        require_equal(
            scaled(selected[index].exponential_r2, 1.0e9),
            expected_exp_r2[index],
            "exponential-r2 certificate",
        )?;
        require_equal(
            scaled(selected[index].gaussian_q, 1.0e9),
            expected_gauss_q[index],
            "Gaussian-q certificate",
        )?;
        require_equal(
            scaled(selected[index].gaussian_r2, 1.0e9),
            expected_gauss_r2[index],
            "Gaussian-r2 certificate",
        )?;
        require_equal(
            scaled(selected[index].monotonic_fraction, 1.0e9),
            expected_monotonic[index],
            "monotonic-fraction certificate",
        )?;
        require_equal(
            scaled(selected[index].mean_alignment, 1.0e9),
            expected_alignment[index],
            "alignment certificate",
        )?;
        require_equal(
            scaled(widths[index].width_squared, 1.0e9),
            expected_width[index],
            "width certificate",
        )?;
        require_equal(
            scaled(widths[index].arc, 1.0e6),
            expected_arc[index],
            "arc certificate",
        )?;
    }
    require_equal(scaled(slope, 1.0e12), 4_796_187_890, "slope certificate")?;
    require_equal(
        scaled(r_squared, 1.0e9),
        994_909_699,
        "regression-r2 certificate",
    )?;

    println!("EVANESCENCE_AUDIT_VERIFIED");
    println!("cycles=7,8,9 side=normal_2_negative");
    println!("kappa_nano={expected_kappa:?}");
    println!("exponential_r2_nano={expected_exp_r2:?}");
    println!("gaussian_q_nano={expected_gauss_q:?}");
    println!("gaussian_r2_nano={expected_gauss_r2:?}");
    println!("monotonic_fraction_nano={expected_monotonic:?}");
    println!("mean_alignment_nano={expected_alignment:?}");
    println!("width_nano={expected_width:?}");
    println!("arc_micro={expected_arc:?}");
    println!(
        "slope_pico={} regression_r2_nano={}",
        scaled(slope, 1.0e12),
        scaled(r_squared, 1.0e9)
    );
    println!("criterion_nano=kappa>0 exp_r2>=950000000 monotonic>=800000000 alignment>=800000000");
    println!("growth_criterion=slope_pico>0 regression_r2_nano>=950000000");
    Ok(())
}

fn main() {
    let root = env::args_os()
        .nth(1)
        .map(PathBuf::from)
        .unwrap_or_else(|| Path::new(env!("CARGO_MANIFEST_DIR")).join("../.."));
    if let Err(error) = run(&root) {
        eprintln!("EVANESCENCE_AUDIT_FAILED: {error}");
        std::process::exit(1);
    }
}
