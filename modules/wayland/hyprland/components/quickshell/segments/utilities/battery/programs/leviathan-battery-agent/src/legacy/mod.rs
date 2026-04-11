mod commands;
mod daemon;
pub(crate) mod shared;

pub fn dispatch_entry(exe_name: &str, args: &[String]) -> Result<(), String> {
    dispatch(exe_name, args)
}

fn dispatch(exe_name: &str, args: &[String]) -> Result<(), String> {
    match exe_name {
        "leviathan-battery" => commands::cmd_battery_summary(),
        "leviathan-battery-info" => commands::cmd_battery_info(),
        "leviathan-battery-thresholds-info" => commands::cmd_thresholds_info(),
        "leviathan-power-profile" => commands::cmd_power_profile(args.get(1).map(String::as_str)),
        "leviathan-battery-threshold" => commands::cmd_threshold(args.get(1).map(String::as_str), args.get(2).map(String::as_str)),
        "leviathan-battery-threshold-pair" => commands::cmd_threshold_pair(args.get(1).map(String::as_str), args.get(2).map(String::as_str)),
        "leviathan-auto-profile-eval" => commands::cmd_auto_profile_eval(),
        "leviathan-battery-monitor" => {
            if args.len() > 1 {
                cmd_from_subcommand(args)
            } else {
                daemon::cmd_event_monitor_daemon(args)
            }
        }
        _ => cmd_from_subcommand(args),
    }
}

fn cmd_from_subcommand(args: &[String]) -> Result<(), String> {
    let Some(cmd) = args.get(1).map(String::as_str) else {
        return Err(String::from("Usage: leviathan-battery-agent <summary|info|thresholds-info|power-profile|threshold|threshold-pair|auto-profile-eval|daemon>"));
    };

    match cmd {
        "summary" => commands::cmd_battery_summary(),
        "info" => commands::cmd_battery_info(),
        "thresholds-info" => commands::cmd_thresholds_info(),
        "power-profile" => commands::cmd_power_profile(args.get(2).map(String::as_str)),
        "threshold" => commands::cmd_threshold(args.get(2).map(String::as_str), args.get(3).map(String::as_str)),
        "threshold-pair" => commands::cmd_threshold_pair(args.get(2).map(String::as_str), args.get(3).map(String::as_str)),
        "auto-profile-eval" => commands::cmd_auto_profile_eval(),
        "daemon" => daemon::cmd_event_monitor_daemon(args),
        _ => Err(String::from("Unknown command")),
    }
}
