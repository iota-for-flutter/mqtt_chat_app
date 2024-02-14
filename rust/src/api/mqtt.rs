use iota_client::{
    block::payload::{Payload, TaggedDataPayload},
    //BrokerOptions,
    Client, 
    MqttEvent, 
    MqttPayload,
    Topic,
};
use tokio::runtime::Runtime;
use anyhow::Result;
//use prefix_hex::encode;

//use std::sync::Once;

use lazy_static::lazy_static;
use log::{info, warn};
use parking_lot::RwLock;

use std::sync::{mpsc::channel, Arc, Mutex};
use std::str;


// use rumqttc::{self, AsyncClient, Event, Incoming, MqttOptions, Transport};
// use rustls::{ClientConfig};
// use rustls_native_certs;

// use rumqttc::{MqttOptions, AsyncClient, QoS};
// use tokio::{task, time};
// use std::time::Duration;
//use std::error::Error;




//static INIT_MQTT_CLIENT_ONCE: Once = Once::new();

pub fn init_mqtt_client(node_url: String) {
   // INIT_MQTT_CLIENT_ONCE.call_once(|| {
        MqttClient::new(&node_url);
   // });
}

lazy_static! {
    static ref MQTT_CLIENT: RwLock<Option<Client>> =
        RwLock::new(None);
}

pub struct MqttClient {
//    node_url: String,
}


impl MqttClient {

    pub fn get_client(node_url: &str) -> Result<Client, anyhow::Error> {
        let rt = Runtime::new().unwrap();
        rt.block_on(async {
            // Create a client with that node.
            let client = Client::builder()
                .with_node(&node_url)?
                //.with_mqtt_broker_options(BrokerOptions::new().use_ws(false))
                .with_ignore_node_health()
                .finish()?;

            Ok(client)
        })
    }

    pub fn init_client(node_url: &str) {

        // Create a client with that node.
        let client = Self::get_client(node_url);

        let mut guard = MQTT_CLIENT.write();
        let overriding = guard.is_some();
        
        *guard = Some(client.unwrap());
        
        drop(guard);
        
        if overriding {
            warn!(
                "MqttClient::init_client but already exist a Client, thus overriding. \
                (This may or may not be a problem. It will happen normally if hot-reload Flutter app.)"
            );
        }       
    }

    pub fn new(node_url: &str) -> Self {
        Self::init_client(node_url);

        //MqttClient { node_url: node_url.to_string() }
        MqttClient {}
    }

    pub fn open_channel_for_tag(tag: &str) -> Result<String> {

        let rt = Runtime::new().unwrap();
        rt.block_on(async {
            if let Some(client) = &*MQTT_CLIENT.read() {
                
                // let client = Client::builder()
                // .with_node("https://api.testnet.shimmer.network")?
                // // .with_mqtt_broker_options(BrokerOptions::new().use_ws(false))
                // .finish()?;
                info!("Get channel()");

                //let (tx, rx): (mpsc::Sender<Topic>, mpsc::Receiver<Topic>) = channel();
                let (tx, _rx) = channel();
                let tx = Arc::new(Mutex::new(tx));
            
                info!("client.mqtt_event_receiver()");
                let mut event_rx = client.mqtt_event_receiver();
                tokio::spawn(async move {
                    while event_rx.changed().await.is_ok() {
                        let event = event_rx.borrow();
                        if *event == MqttEvent::Disconnected {
                            println!("mqtt disconnected");
                            std::process::exit(1);
                        }
                    }
                });

                // -------------------
                // let mut bytes_vec = vec![0; 32];
                // let tag_as_bytes_vec = "TestTag".as_bytes().to_vec();
                // let len = tag_as_bytes_vec.len();
                // for t in 0..len {
                //     let m = 32 - len + t;
                //     //std::mem::replace(&mut bytes_vec[m], tag_as_bytes_vec[t]);
                //     bytes_vec[m] = tag_as_bytes_vec[t];
                // } 
                let bytes_vec = Self::to_bytes_vec(tag);  
                let tag_as_hex = prefix_hex::encode(bytes_vec);
                let tag_as_hex_string = format!("{}", tag_as_hex);
                let topic_string: String = "blocks/tagged-data/".to_string() + &tag_as_hex_string;
                // -------------------

                info!("client.subscribe()");
                let resp = client.clone()
                  .subscribe(
                    vec![
                       Topic::try_from(topic_string.to_string())?,
                     ],
                    move |event| {
                        println!("Topic: {}", event.topic);
                        match &event.payload {
                            MqttPayload::Json(val) => println!("{}", serde_json::to_string(&val).unwrap()),
                            MqttPayload::Block(block) => {
                                info!("RECEIVING BLOCKID IS {}", block.id());
                                if let Some(Payload::TaggedData(payload)) = block.payload() {
                                    info!(
                                        "RECEIVING PAYLOAD TAG: {:?}",
                                        payload.tag().to_vec()
                                        //String::from_utf8(payload.tag().to_vec()).expect("found invalid UTF-8")
                                    );
                                    let bytes_vec = payload.data().to_vec();
                                    let mystr: &str = str::from_utf8(&bytes_vec).unwrap();
                                    info!("{}",mystr)
                                    // info!(
                                    //     "RECEIVING PAYLOAD DATA: {:?}",
                                    //     payload.data().to_vec()
                                    //     //String::from_utf8(payload.data().to_vec()).expect("found invalid UTF-8")
                                    // );
                                }
                            },
                            MqttPayload::MilestonePayload(ms) => println!("{ms:?}"),
                            MqttPayload::Receipt(receipt) => println!("{receipt:?}"),
                        }
                        tx.lock().unwrap().send(()).unwrap();
                    },
                )
                .await;

                let r = match resp {
                    Err(e) => return Err(e.into()), // tries to convert the error into the required type if necessary (and if possible)
                    Ok(()) => "CHANNEL WAS OPENED SUCCESSFULLY :-))".into()
                };
                               
                Ok(r)
            } else {
                Ok("CHANNEL COULD NOT BE OPENED :-((".into())
            }
        })
    }

    pub fn close_channel() -> Result<String> {
        let rt = Runtime::new().unwrap();
        rt.block_on(async {
            if let Some(client) = &*MQTT_CLIENT.read() {
                client.clone().subscriber().disconnect().await?;
                Ok("CHANNEL WAS CLOSED SUCCESSFULLY".into())
            } else {
                Ok("CHANNEL WAS NOT CLOSED :-((".into())
            }           
        })      
    }

    // Post a TAGGED DATA block
    // Example: https://wiki.iota.org/shimmer/iota.rs/how_tos/post_block/
    pub fn publish_message(tag: &str, user_id: String, user: String, message: String) -> Result<String> {
        let domain: String = String::from("com.mtangle.mqttchat");
        let full_message = domain + "@@@" + &tag + "@@@" + &user_id + "@@@" + &user + "@@@" + &message;

        // Create a custom payload.
        //let tagged_data_payload = TaggedDataPayload::new(tag.as_bytes().to_vec(), full_message.as_bytes().to_vec())?;
        // -------------------
        // let mut bytes_vec = vec![0; 32];
        // let tag_as_bytes_vec = "TestTag".as_bytes().to_vec();
        // let len = tag_as_bytes_vec.len();
        // for t in 0..len {
        //     let m = 32 - len + t;
        //     //std::mem::replace(&mut bytes_vec[m], tag_as_bytes_vec[t]);
        //     bytes_vec[m] = tag_as_bytes_vec[t];
        // }   
        let tag_as_bytes_vec = Self::to_bytes_vec(tag);      
        let tagged_data_payload = TaggedDataPayload::new(tag_as_bytes_vec, full_message.as_bytes().to_vec())?;

        // Create and send the block with the custom payload.
        let rt = Runtime::new().unwrap();
        rt.block_on(async {
            if let Some(client) = &*MQTT_CLIENT.read() {
                
                let block = client
                    .block()
                    .finish_block(Some(Payload::from(tagged_data_payload)))
                    .await?;
                
                let block_id = client.post_block(&block).await?;

                // Check block_id:
                // https://explorer.shimmer.network/testnet/block/<block_id>
                //info!("TAGGED DATA BLOCK WAS PUBLISHED: {block_id:?}");

                //Ok(serde_json::to_string_pretty(&block).unwrap())
                Ok(block_id.to_string())

            } else {
                // "Error" case - TODO: Ok -> Err
                Ok("0x00".into())
            }
            
        })

        // let formatted_message = format!("{}", full_message);
        // info!("{}", formatted_message);
     
        // Ok("Message was sent".into())     
    }

    /// Converts a string (in this case the tag) into a vector of 32 bytes (= 64 chars as hex);
    /// 64 chars because of regular expression in iota.rs -> src/node_api/mqtt/types.rs -> Topic::try_new()
    /// r"^blocks/tagged-data/0x([a-f0-9]{64})$"
    /// Example result of this fn (tag = "TestTag"): 
    /// [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 84, 101, 115, 116, 84, 97, 103]
    fn to_bytes_vec(tag: &str) -> Vec<u8> {
        let mut bytes_vec = vec![0; 32];
        let tag_as_bytes_vec = tag.as_bytes().to_vec();
        let len = tag_as_bytes_vec.len();
        for t in 0..len {
            let m = 32 - len + t;
            bytes_vec[m] = tag_as_bytes_vec[t];
        } 
        bytes_vec
    }




    // pub fn mosquitto_mqtt() -> Result<()> {

    //     let rt = Runtime::new().unwrap();
    //     rt.block_on(async {
    //     //let mut mqttoptions = MqttOptions::new("nos", "test.mosquitto.org", 8883);
    //     let mut mqttoptions = MqttOptions::new("rumqtt-sync", "test.mosquitto.org", 1883);
    //         mqttoptions.set_keep_alive(std::time::Duration::from_secs(5));
    //         //mqttoptions.set_credentials("rw", "readwrite");

    //         // Use rustls-native-certs to load root certificates from the operating system.
    //         let mut root_cert_store = rustls::RootCertStore::empty();
    //         for cert in rustls_native_certs::load_native_certs().expect("could not load platform certs") {
    //             root_cert_store.add(&rustls::Certificate(cert.0))?;
    //         }

    //         let client_config = ClientConfig::builder()
    //             .with_safe_defaults()
    //             .with_root_certificates(root_cert_store)
    //             .with_no_client_auth();

    //         mqttoptions.set_transport(Transport::tls_with_config(client_config.into()));

    //         let (_client, mut eventloop) = AsyncClient::new(mqttoptions, 10);

    //         loop {
    //             match eventloop.poll().await {
    //                 Ok(Event::Incoming(Incoming::Publish(p))) => {
    //                     println!("Topic: {}, Payload: {:?}", p.topic, p.payload);
    //                 }
    //                 Ok(Event::Incoming(i)) => {
    //                     println!("Incoming = {:?}", i);
    //                 }
    //                 Ok(Event::Outgoing(o)) => println!("Outgoing = {:?}", o),
    //                 Err(e) => {
    //                     println!("Error = {:?}", e);
    //                 }
    //             }
    //         }
    //     })
    // }
    // pub fn mosquitto_mqtt() -> Result<()> {

    //     let rt = Runtime::new().unwrap();
    //     rt.block_on(async {

    //         let mut mqttoptions = MqttOptions::new("rumqtt-async", "test.mosquitto.org", 1883);
    //         mqttoptions.set_keep_alive(Duration::from_secs(5));
            
    //         let (client, mut eventloop) = AsyncClient::new(mqttoptions, 10);
    //         client.subscribe("hello/rumqtt", QoS::AtMostOnce).await.unwrap();
            
    //         task::spawn(async move {
    //             for i in 0..10 {
    //                 client.publish("hello/rumqtt", QoS::AtLeastOnce, false, vec![i; i as usize]).await.unwrap();
    //                 time::sleep(Duration::from_millis(100)).await;
    //             }
    //         });
            
    //         loop {
    //             let notification = eventloop.poll().await.unwrap();
    //             println!("Received = {:?}", notification);
    //         }


    //      })
    // }


 }






// https://stackoverflow.com/questions/27791532/how-do-i-create-a-global-mutable-singleton/27826181#27826181
// use lazy_static::lazy_static; // 1.4.0
// use std::sync::Mutex;

// lazy_static! {
//     static ref ARRAY: Mutex<Vec<u8>> = Mutex::new(vec![]);
// }

// pub fn do_a_call() {
//     ARRAY.lock().unwrap().push(1);
// }

// pub fn get_array_length() -> usize {
//     let result = ARRAY.lock().unwrap().len();
//     result
// }


// use std::sync::{Arc, RwLock};

// #[derive(Default)]
// struct ConfigInner {
//     debug_mode: bool,
// }

// struct Config {
//     inner: RwLock<ConfigInner>,
// }

// impl Config {
//     pub fn new() -> Arc<Config> {
//         Arc::new(Config { inner: RwLock::new(Default::default()) })
//     }
//     pub fn current() -> Arc<Config> {
//         CURRENT_CONFIG.with(|c| c.clone())
//     }
//     pub fn debug_mode(&self) -> bool {
//         self.inner.read().unwrap().debug_mode
//     }
//     pub fn set_debug_mode(&self, value: bool) {
//         self.inner.write().unwrap().debug_mode = value;
//     }
// }

// thread_local! {
//     static CURRENT_CONFIG: Arc<Config> = Config::new();
// }

// // fn main() {
// //     let config = Config::current();
// //     config.set_debug_mode(true);
// //     if config.debug_mode() {
// //         // do something
// //     }
// // }