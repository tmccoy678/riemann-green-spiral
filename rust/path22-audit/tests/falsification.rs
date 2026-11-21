use std::fs;
use std::path::{Path, PathBuf};
use std::process::{Command, Output};
use std::time::{SystemTime, UNIX_EPOCH};

struct Fixture(PathBuf);

impl Drop for Fixture {
    fn drop(&mut self) {
        let _ = fs::remove_dir_all(&self.0);
    }
}

fn source_root() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR")).join("../..")
}

fn fixture(label: &str) -> Fixture {
    let nonce = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .expect("system clock")
        .as_nanos();
    let root = std::env::temp_dir().join(format!(
        "path22-audit-{label}-{}-{nonce}",
        std::process::id()
    ));
    fs::create_dir_all(root.join("data")).expect("create fixture");
    for name in [
        "riemann_paths.tsv",
        "path22_flow.tsv",
        "path22_field_meta.tsv",
        "path22_neighborhood_0125.tsv",
        "path22_neighborhood_seeds.tsv",
    ] {
        fs::copy(
            source_root().join("data").join(name),
            root.join("data").join(name),
        )
        .expect("copy fixture data");
    }
    Fixture(root)
}

fn run(root: &Path) -> Output {
    Command::new(env!("CARGO_BIN_EXE_path22-audit"))
        .arg(root)
        .output()
        .expect("run path22 audit")
}

fn rewrite_line(path: &Path, mutator: impl Fn(&str) -> Option<String>) {
    let source = fs::read_to_string(path).expect("read fixture");
    let mut changed = false;
    let rewritten = source
        .lines()
        .map(|line| {
            if !changed && let Some(replacement) = mutator(line) {
                changed = true;
                replacement
            } else {
                line.to_owned()
            }
        })
        .collect::<Vec<_>>()
        .join("\n");
    assert!(changed, "mutation target not found");
    fs::write(path, format!("{rewritten}\n")).expect("write fixture");
}

fn assert_failure(output: Output, expected: &str) {
    assert!(!output.status.success(), "mutation unexpectedly passed");
    let stderr = String::from_utf8_lossy(&output.stderr);
    assert!(
        stderr.contains(expected),
        "expected {expected:?} in stderr, got {stderr:?}"
    );
}

#[test]
fn committed_artifacts_pass() {
    let fixture = fixture("baseline");
    let output = run(&fixture.0);
    assert!(
        output.status.success(),
        "baseline failed: {}",
        String::from_utf8_lossy(&output.stderr)
    );
}

#[test]
fn nonfinite_velocity_is_rejected() {
    let fixture = fixture("nonfinite");
    let path = fixture.0.join("data/path22_flow.tsv");
    rewrite_line(&path, |line| {
        let mut fields = line.split('\t').collect::<Vec<_>>();
        (fields.first() == Some(&"1230")).then(|| {
            fields[4] = "NaN";
            fields.join("\t")
        })
    });
    assert_failure(run(&fixture.0), "non-finite float");
}

#[test]
fn reordered_sample_is_rejected() {
    let fixture = fixture("reordered");
    let path = fixture.0.join("data/path22_flow.tsv");
    rewrite_line(&path, |line| {
        let mut fields = line.split('\t').collect::<Vec<_>>();
        (fields.first() == Some(&"2")).then(|| {
            fields[0] = "1";
            fields.join("\t")
        })
    });
    assert_failure(run(&fixture.0), "expected point 2, found 1");
}

#[test]
fn altered_return_coordinate_is_rejected() {
    let fixture = fixture("witness");
    let path = fixture.0.join("data/riemann_paths.tsv");
    rewrite_line(&path, |line| {
        let mut fields = line.split('\t').collect::<Vec<_>>();
        (fields.first() == Some(&"22") && fields.get(1) == Some(&"1176")).then(|| {
            fields[2] = "110.5";
            fields.join("\t")
        })
    });
    assert_failure(run(&fixture.0), "coordinate bits do not match path 22");
}

#[test]
fn inconsistent_speed_is_rejected() {
    let fixture = fixture("speed");
    let path = fixture.0.join("data/path22_flow.tsv");
    rewrite_line(&path, |line| {
        let mut fields = line.split('\t').collect::<Vec<_>>();
        (fields.first() == Some(&"1230")).then(|| {
            fields[7] = "9";
            fields.join("\t")
        })
    });
    assert_failure(run(&fixture.0), "speed residual");
}

#[test]
fn injected_path_inside_channel_is_rejected() {
    let fixture = fixture("intrusion");
    let path = fixture.0.join("data/riemann_paths.tsv");
    rewrite_line(&path, |line| {
        let mut fields = line.split('\t').collect::<Vec<_>>();
        (fields.first() == Some(&"29") && fields.get(1) == Some(&"207")).then(|| {
            fields[2] = "111.63732274636249";
            fields[3] = "24.892344691831877";
            fields[4] = "4.3752074559263665";
            fields.join("\t")
        })
    });
    assert_failure(run(&fixture.0), "another path enters the two-unit channel");
}

#[test]
fn altered_neighborhood_summary_is_rejected() {
    let fixture = fixture("neighborhood-summary");
    let path = fixture.0.join("data/path22_neighborhood_seeds.tsv");
    rewrite_line(&path, |line| {
        let mut fields = line.split('\t').collect::<Vec<_>>();
        (fields.first() == Some(&"545")).then(|| {
            fields[3] = "2676";
            fields.join("\t")
        })
    });
    assert_failure(run(&fixture.0), "summary identity mismatch");
}

#[test]
fn exterior_sample_is_rejected() {
    let fixture = fixture("exterior");
    let path = fixture.0.join("data/path22_neighborhood_0125.tsv");
    rewrite_line(&path, |line| {
        let mut fields = line.split('\t').collect::<Vec<_>>();
        (fields.first() == Some(&"1") && fields.get(3) == Some(&"1")).then(|| {
            fields[4] = "200";
            fields.join("\t")
        })
    });
    assert_failure(run(&fixture.0), "outside measured field");
}
