#[cfg(feature = "c_api")]
use qualifier_attr::fn_qualifiers;

macro_rules! hello_impl {
    () => {
        println!("Hello, world!");       
    };
}

// #[cfg(feature = "c_api")]
// #[no_mangle]
// pub extern "C" fn hello() {
//     hello_impl!();
// }

#[cfg_attr(feature="c_api", no_mangle, fn_qualifiers(extern "C"))]
pub fn hello() {
    hello_impl!();    
}
