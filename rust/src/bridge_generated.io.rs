use super::*;
// Section: wire functions

#[no_mangle]
pub extern "C" fn wire_create_log_stream(port_: i64) {
    wire_create_log_stream_impl(port_)
}

#[no_mangle]
pub extern "C" fn wire_rust_set_up(port_: i64) {
    wire_rust_set_up_impl(port_)
}

#[no_mangle]
pub extern "C" fn wire_publish_message(
    port_: i64,
    tag: *mut wire_uint_8_list,
    user_id: *mut wire_uint_8_list,
    user: *mut wire_uint_8_list,
    message: *mut wire_uint_8_list,
) {
    wire_publish_message_impl(port_, tag, user_id, user, message)
}

#[no_mangle]
pub extern "C" fn wire_setup_mqtt(port_: i64, node_url: *mut wire_uint_8_list) {
    wire_setup_mqtt_impl(port_, node_url)
}

#[no_mangle]
pub extern "C" fn wire_subscribe_for_tag(port_: i64, tag: *mut wire_uint_8_list) {
    wire_subscribe_for_tag_impl(port_, tag)
}

#[no_mangle]
pub extern "C" fn wire_unsubscribe(port_: i64) {
    wire_unsubscribe_impl(port_)
}

#[no_mangle]
pub extern "C" fn wire_greet(port_: i64) {
    wire_greet_impl(port_)
}

#[no_mangle]
pub extern "C" fn wire_platform(port_: i64) {
    wire_platform_impl(port_)
}

#[no_mangle]
pub extern "C" fn wire_rust_release_mode(port_: i64) {
    wire_rust_release_mode_impl(port_)
}

// Section: allocate functions

#[no_mangle]
pub extern "C" fn new_uint_8_list_0(len: i32) -> *mut wire_uint_8_list {
    let ans = wire_uint_8_list {
        ptr: support::new_leak_vec_ptr(Default::default(), len),
        len,
    };
    support::new_leak_box_ptr(ans)
}

// Section: related functions

// Section: impl Wire2Api

impl Wire2Api<String> for *mut wire_uint_8_list {
    fn wire2api(self) -> String {
        let vec: Vec<u8> = self.wire2api();
        String::from_utf8_lossy(&vec).into_owned()
    }
}

impl Wire2Api<Vec<u8>> for *mut wire_uint_8_list {
    fn wire2api(self) -> Vec<u8> {
        unsafe {
            let wrap = support::box_from_leak_ptr(self);
            support::vec_from_leak_ptr(wrap.ptr, wrap.len)
        }
    }
}
// Section: wire structs

#[repr(C)]
#[derive(Clone)]
pub struct wire_uint_8_list {
    ptr: *mut u8,
    len: i32,
}

// Section: impl NewWithNullPtr

pub trait NewWithNullPtr {
    fn new_with_null_ptr() -> Self;
}

impl<T> NewWithNullPtr for *mut T {
    fn new_with_null_ptr() -> Self {
        std::ptr::null_mut()
    }
}

// Section: sync execution mode utility

#[no_mangle]
pub extern "C" fn free_WireSyncReturn(ptr: support::WireSyncReturn) {
    unsafe {
        let _ = support::box_from_leak_ptr(ptr);
    };
}
