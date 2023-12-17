use async_process::Command;

pub async fn mount(source: &str, mount_point: &str) -> Result<(), &'static str> {
    let exit_status = Command::new("mount")
        .args(&["--bind", source, mount_point])
        .status()
        .await
        .unwrap();
    match exit_status.success() {
        true => Ok(()),
        false => Err("Failed to run mount command"),
    }
}
