use actix_web::{web, App, HttpServer, HttpResponse, middleware};
use actix_files as fs;
use serde_json::json;
use std::env;

async fn health() -> HttpResponse {
    HttpResponse::Ok().json(json!({
        "status": "healthy",
        "version": "0.1.0"
    }))
}

async fn info() -> HttpResponse {
    // Check if SSH port is exposed (dev mode)
    let dev_mode = env::var("DEV_MODE").unwrap_or_default() == "true";
    
    // Simple Redis check
    let redis_status = match redis::Client::open("redis://127.0.0.1:6379") {
        Ok(client) => match client.get_connection() {
            Ok(mut conn) => {
                match redis::cmd("PING").query::<String>(&mut conn) {
                    Ok(_) => "Connected",
                    Err(_) => "Error"
                }
            },
            Err(_) => "Connection Failed"
        },
        Err(_) => "Not Available"
    };

    // Simple Neo4j check (just HTTP endpoint)
    let neo4j_status = match reqwest::get("http://localhost:7474").await {
        Ok(resp) if resp.status().is_success() => "Connected",
        Ok(_) => "Running",
        Err(_) => "Not Available"
    };

    HttpResponse::Ok().json(json!({
        "dev_mode": dev_mode,
        "redis_status": redis_status,
        "neo4j_status": neo4j_status,
        "services": {
            "redis": "redis://localhost:6379",
            "neo4j": "bolt://localhost:7687"
        }
    }))
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    env_logger::init_from_env(env_logger::Env::new().default_filter_or("info"));

    let port = env::var("PORT").unwrap_or_else(|_| "8443".to_string());
    let bind_addr = format!("0.0.0.0:{}", port);

    println!("🚀 Kalisi Demo Server starting on https://{}", bind_addr);

    // Check if we should use HTTPS
    let cert_file = env::var("TLS_CERT").unwrap_or_else(|_| "/certs/cert.pem".to_string());
    let key_file = env::var("TLS_KEY").unwrap_or_else(|_| "/certs/key.pem".to_string());
    
    let server = HttpServer::new(|| {
        App::new()
            .wrap(middleware::Logger::default())
            .route("/api/health", web::get().to(health))
            .route("/api/info", web::get().to(info))
            .service(fs::Files::new("/", "/app/static").index_file("index.html"))
    });

    // Try HTTPS first, fall back to HTTP
    if std::path::Path::new(&cert_file).exists() && std::path::Path::new(&key_file).exists() {
        println!("✅ TLS certificates found, starting HTTPS server");
        server
            .bind_openssl(&bind_addr, {
                use openssl::ssl::{SslAcceptor, SslMethod, SslFiletype};
                let mut builder = SslAcceptor::mozilla_intermediate(SslMethod::tls())?;
                builder.set_private_key_file(&key_file, SslFiletype::PEM)?;
                builder.set_certificate_chain_file(&cert_file)?;
                builder
            })?
            .run()
            .await
    } else {
        println!("⚠️  No TLS certificates found, starting HTTP server");
        server
            .bind(&bind_addr)?
            .run()
            .await
    }
}