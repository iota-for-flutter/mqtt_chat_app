mod logger;
mod mqtt;

use anyhow::Result;
use flutter_rust_bridge::StreamSink;

use log::{error, info, warn};

pub struct LogEntry {
    pub time_millis: i64,
    pub level: i32,
    pub tag: String,
    pub user_id: String,
    pub user: String,
    pub msg: String,
}

pub fn create_log_stream(s: StreamSink<LogEntry>) -> Result<()> {
    logger::SendToDartLogger::set_stream_sink(s);
    Ok(())
}

pub fn rust_set_up() {
    logger::init_logger();
}

// This is the entry point of your Rust library.
// When adding new code to your project, note that only items used
// here will be transformed to their Dart equivalents.

// pub fn get_node_info(network_info: NetworkInfo) -> Result<String> {
//     let rt = Runtime::new().unwrap();
//     rt.block_on(async {

//         let node_url = network_info.node_url;

//         // Create a client with that node.
//         let client = Client::builder()
//             .with_node(&node_url)?
//             .with_ignore_node_health()
//             .finish()?;

//         // Get node info.
//         let info = client.get_info().await?;

//         Ok(serde_json::to_string_pretty(&info).unwrap())
//         //Ok(info.node_info.base_token.name)
//     })
// }

pub fn publish_message(
    tag: String,
    user_id: String,
    user: String,
    message: String,
) -> Result<String> {
    // let domain: String = String::from("com.mtangle.mqttchat");
    // let full_message = domain + "@@@" + &tag + "@@@" + &user_id + "@@@" + &user + "@@@" + &message;

    // let rt = Runtime::new().unwrap();
    // rt.block_on(async {

    //     // Create a client with that node.
    //     let mut client = Client::builder()
    //         .with_node(&node_url)?
    //         .with_ignore_node_health()
    //         .finish()?;

    //     // Create a custom payload.
    //     let tagged_data_payload = TaggedDataPayload::new("Your tag".as_bytes().to_vec(), "Your data".as_bytes().to_vec())?;

    //     // Create and send the block with the custom payload.
    //     let block = client
    //         .block()
    //         .finish_block(Some(Payload::from(tagged_data_payload)))
    //         .await?;

    //     Ok(serde_json::to_string_pretty(&block).unwrap())
    // })

    // Versuch, einen globalen Vektor zu befüllen und die Länge später auszulesen
    // https://stackoverflow.com/questions/27791532/how-do-i-create-a-global-mutable-singleton/27826181#27826181
    // if &message == "OUT" {
    //     let result = mqtt::get_array_length();
    //     info!("Länge des Vektors: {}", result);
    // } else {
    //     mqtt::do_a_call();
    // }

    // let formatted_message = format!("{}", full_message);
    // info!("{}", formatted_message);

    let block_id = mqtt::MqttClient::publish_message(&tag, user_id, user, message).unwrap();

    Ok(block_id)
}

pub fn setup_mqtt(node_url: String) -> Result<String> {
    mqtt::init_mqtt_client(node_url);

    //mqtt::MqttClient::mosquitto_mqtt()?;

    Ok("Init MQTT Client was invoked - return to Flutter".into())
}

pub fn subscribe_for_tag(tag: String) -> String {
    info!("Execute MQTT subscribe for tag {}", tag);
    mqtt::MqttClient::open_channel_for_tag(&tag).unwrap();
    "subscribe finished".into()
}

pub fn unsubscribe() -> String {
    info!("Execute MQTT unsubscribe");
    mqtt::MqttClient::close_channel().unwrap();
    "unsubscribe finished".into()
}

// ----------------

pub fn greet() -> String {
    warn!("WARNING --------------- hello I am a log from Rust");
    info!("INFO    --------------- hello I am a log from Rust");
    error!("ERROR  --------------- hello I am a log from Rust");

    info!("com.mtangle.mqttchat@@@MQTT_EXAMPLE@@@82091008-a484-4a89-ae75-a22bf8d6f3ac@@@Kai@@@This is a first test message." );
    info!("com.mtangle.mqttchat@@@MQTT_EXAMPLE@@@82091008-a484-4a89-ae75-a22bf8d6f3bb@@@Karina@@@This is a second test message." );

    "Hello from Rust! 🦀".into()
}

// A plain enum without any fields. This is similar to Dart- or C-style enums.
// flutter_rust_bridge is capable of generating code for enums with fields
// (@freezed classes in Dart and tagged unions in C).
pub enum Platform {
    Unknown,
    Android,
    Ios,
    Windows,
    Unix,
    MacIntel,
    MacApple,
    Wasm,
}

// A function definition in Rust. Similar to Dart, the return type must always be named
// and is never inferred.
pub fn platform() -> Platform {
    // This is a macro, a special expression that expands into code. In Rust, all macros
    // end with an exclamation mark and can be invoked with all kinds of brackets (parentheses,
    // brackets and curly braces). However, certain conventions exist, for example the
    // vector macro is almost always invoked as vec![..].
    //
    // The cfg!() macro returns a boolean value based on the current compiler configuration.
    // When attached to expressions (#[cfg(..)] form), they show or hide the expression at compile time.
    // Here, however, they evaluate to runtime values, which may or may not be optimized out
    // by the compiler. A variety of configurations are demonstrated here which cover most of
    // the modern oeprating systems. Try running the Flutter application on different machines
    // and see if it matches your expected OS.
    //
    // Furthermore, in Rust, the last expression in a function is the return value and does
    // not have the trailing semicolon. This entire if-else chain forms a single expression.
    if cfg!(windows) {
        Platform::Windows
    } else if cfg!(target_os = "android") {
        Platform::Android
    } else if cfg!(target_os = "ios") {
        Platform::Ios
    } else if cfg!(all(target_os = "macos", target_arch = "aarch64")) {
        Platform::MacApple
    } else if cfg!(target_os = "macos") {
        Platform::MacIntel
    } else if cfg!(target_family = "wasm") {
        Platform::Wasm
    } else if cfg!(unix) {
        Platform::Unix
    } else {
        Platform::Unknown
    }
}

// The convention for Rust identifiers is the snake_case,
// and they are automatically converted to camelCase on the Dart side.
pub fn rust_release_mode() -> bool {
    cfg!(not(debug_assertions))
}
