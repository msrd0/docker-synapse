use std::process::exit;

fn main() {
	let res = match attohttpc::get("http://localhost:8008/_matrix/federation/v1/version").send() {
		Ok(res) => res,
		Err(e) => {
			eprintln!("ERROR: {}", e);
			exit(1);
		}
	};
	if !res.is_success() {
		eprintln!("Response returned status code {}", res.status());
		exit(1);
	}
}
