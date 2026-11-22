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
        "evanescence-audit-{label}-{}-{nonce}",
        std::process::id()
    ));
    fs::create_dir_all(root.join("data")).expect("create fixture");
    for name in [
        "local_evanescence.tsv",
        "gaussian_width_growth.tsv",
        "comsol_evanescence.tsv",
        "comsol_gaussian_width_growth.tsv",
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
    Command::new(env!("CARGO_BIN_EXE_evanescence-audit"))
        .arg(root)
        .output()
        .expect("run audit")
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
        "expected {expected:?}, got {stderr:?}"
    );
}

#[test]
fn committed_data_passes() {
    let fixture = fixture("baseline");
    let output = run(&fixture.0);
    assert!(
        output.status.success(),
        "{}",
        String::from_utf8_lossy(&output.stderr)
    );
}

#[test]
fn altered_gaussian_q_is_rejected() {
    let fixture = fixture("gaussian-q");
    rewrite_line(&fixture.0.join("data/local_evanescence.tsv"), |line| {
        let mut fields = line.split('\t').collect::<Vec<_>>();
        (fields.first() == Some(&"8") && fields.get(2) == Some(&"normal_2_negative")).then(|| {
            fields[5] = "0.5";
            fields.join("\t")
        })
    });
    assert_failure(run(&fixture.0), "Gaussian-q binding mismatch");
}

#[test]
fn broken_alignment_is_rejected() {
    let fixture = fixture("alignment");
    rewrite_line(&fixture.0.join("data/local_evanescence.tsv"), |line| {
        let mut fields = line.split('\t').collect::<Vec<_>>();
        (fields.first() == Some(&"8") && fields.get(2) == Some(&"normal_2_negative")).then(|| {
            fields[8] = "0";
            fields.join("\t")
        })
    });
    assert_failure(run(&fixture.0), "evanescence criterion mismatch");
}

#[test]
fn altered_arc_is_rejected() {
    let fixture = fixture("arc");
    rewrite_line(&fixture.0.join("data/gaussian_width_growth.tsv"), |line| {
        let mut fields = line.split('\t').collect::<Vec<_>>();
        (fields.first() == Some(&"9")).then(|| {
            fields[1] = "30";
            fields.join("\t")
        })
    });
    assert_failure(run(&fixture.0), "linear prediction mismatch");
}

#[test]
fn broken_comsol_forward_flux_is_rejected() {
    let fixture = fixture("comsol-forward");
    rewrite_line(&fixture.0.join("data/comsol_evanescence.tsv"), |line| {
        let mut fields = line.split('\t').collect::<Vec<_>>();
        (fields.first() == Some(&"8")).then(|| {
            fields[4] = "0";
            fields.join("\t")
        })
    });
    assert_failure(run(&fixture.0), "COMSOL Maxwell criterion mismatch");
}
