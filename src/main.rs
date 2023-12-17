use std::future::Future;

use tokio::{join, try_join};

mod board_generations;
mod get_audio_choice;
mod get_board_name;
mod has_max98357a;
mod mount;

use board_generations::get_board_generations;
use get_audio_choice::{get_audio_choice, AudioChoice};
use get_board_name::get_board_name;
use has_max98357a::has_max98357a;
use mount::mount;

#[tokio::main]

async fn main() {
    let (board_name, board_generations) = join!(get_board_name(), get_board_generations());
    let board_name = board_name.unwrap();
    let board_generation = board_generations
        .get(&board_name)
        .map(|generation| generation.as_str());
    dbg!(board_generation);

    match board_generation {
        Some(board_generation) => {
            let enable_sof = || async {
                println!("Enabling SOF audio");
                try_join!(
                    mount(
                        "/usr/share/eupnea-audio/snd-sof.conf",
                        "/etc/modprobe.d/snd-sof.conf",
                    ),
                    async {
                        if board_generation == "apl" {
                            mount(
                                "/usr/share/eupnea-audio/apl-sof.conf",
                                "/etc/modprobe.d/apl-sof.conf",
                            )
                            .await?;
                            Ok(())
                        } else {
                            Ok(())
                        }
                    }
                )
                .unwrap();
            };

            async fn enable_avs<T: Future<Output = bool>>(use_max98357a: T) {
                println!("Enabling AVS");
                try_join!(
                    mount(
                        "/usr/share/eupnea-audio/snd-avs.conf",
                        "/etc/modprobe.d/snd-avs.conf"
                    ),
                    mount(
                        "/usr/share/eupnea-audio/51-avs-dmic.lua",
                        "/etc/wireplumber/main.lua.d/51-avs-dmic.lua"
                    ),
                    async {
                        let use_max98357a = use_max98357a.await;
                        if use_max98357a {
                            println!("Enabling max98357a");
                            mount(
                                "/usr/share/eupnea-audio/max98357a-tplg.bin",
                                "/usr/lib/firmware/intel/avs/max98357a-tplg.bin",
                            )
                            .await?;
                            Ok(())
                        } else {
                            println!("Not enabling max98357a");
                            Ok(())
                        }
                    }
                )
                .unwrap();
            }

            match board_generation {
                "bdw" | "byt" | "bsw" => {
                    println!("Enabling bsw audio");
                    mount(
                        "/usr/share/eupnea-audio/hifi2-sof.conf",
                        "/etc/modprobe.d/hifi2-sof.conf",
                    )
                    .await
                    .unwrap();
                }
                "skl" | "kbl" => {
                    enable_avs(async {
                        let (has_max98357a, audio_choice) =
                            join!(has_max98357a(), get_audio_choice());
                        let max98357a_chosen = match audio_choice {
                            Some(audio_choice) => match audio_choice {
                                AudioChoice::AvsWithMax98357a => true,
                                _ => false,
                            },
                            None => false,
                        };
                        let use_max98357a = has_max98357a && max98357a_chosen;
                        use_max98357a
                    })
                    .await;
                }
                "apl" => {
                    let (has_max98357a, audio_choice) = join!(has_max98357a(), get_audio_choice());
                    let audio_to_use = match audio_choice {
                        Some(audio_choice) => match audio_choice {
                            AudioChoice::AvsWithMax98357a => match has_max98357a {
                                true => AudioChoice::AvsWithMax98357a,
                                false => AudioChoice::AvsWithoutMax98357a,
                            },
                            _ => audio_choice,
                        },
                        // It's better to have stable audio with speakers working by default than audio with only headphone jack and internal mic working.
                        None => AudioChoice::Sof,
                    };
                    match audio_to_use {
                        AudioChoice::Sof => enable_sof().await,
                        AudioChoice::AvsWithoutMax98357a => enable_avs(async { false }).await,
                        AudioChoice::AvsWithMax98357a => enable_avs(async { true }).await,
                    }
                }
                "glk" | "cml" | "tgl" | "jsl" | "adl" => enable_sof().await,
                "stoney" | "picasso" | "cezanne" | "mendocino" | "mt8183" => {
                    println!("Audio for this Chromebook does not need anything in /etc")
                }
                _ => println!("Audio not implemented for {} yet", board_generation),
            }
        }
        None => {
            println!("Not a chromebook. Not overlaying Chromebook audio.")
        }
    }
}
