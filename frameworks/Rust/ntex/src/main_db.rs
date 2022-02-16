#[global_allocator]
static GLOBAL: mimalloc::MiMalloc = mimalloc::MiMalloc;

use std::{pin::Pin, task::Context, task::Poll};

use futures::future::{ok, Future, FutureExt};
use ntex::http::header::{HeaderValue, CONTENT_TYPE, SERVER};
use ntex::http::{HttpService, KeepAlive, Request, Response};
use ntex::service::{Service, ServiceFactory};
use ntex::web::{Error, HttpResponse};
use ntex::{time::Seconds, util::BytesMut, util::PoolId};

#[cfg(target_os = "macos")]
use serde_json as simd_json;

mod db;
mod utils;

struct App(db::PgConnection);

impl Service<Request> for App {
    type Response = Response;
    type Error = Error;
    type Future = Pin<Box<dyn Future<Output = Result<Response, Error>>>>;

    #[inline]
    fn poll_ready(&self, _: &mut Context<'_>) -> Poll<Result<(), Self::Error>> {
        Poll::Ready(Ok(()))
    }

    fn call(&self, req: Request) -> Self::Future {
        match req.path() {
            "/db" => Box::pin(self.0.get_world().map(|body| {
                Ok(HttpResponse::Ok()
                    .header(SERVER, HeaderValue::from_static("N"))
                    .header(CONTENT_TYPE, HeaderValue::from_static("application/json"))
                    .body(body))
            })),
            "/fortunes" => Box::pin(self.0.tell_fortune().map(|body| {
                Ok(HttpResponse::Ok()
                    .header(SERVER, HeaderValue::from_static("N"))
                    .header(
                        CONTENT_TYPE,
                        HeaderValue::from_static("text/html; charset=utf-8"),
                    )
                    .body(body))
            })),
            "/query" => Box::pin(
                self.0
                    .get_worlds(utils::get_query_param(req.uri().query()))
                    .map(|worlds| {
                        let mut body = BytesMut::with_capacity(35 * worlds.len());
                        let _ = simd_json::to_writer(crate::utils::Writer(&mut body), &worlds);
                        Ok(HttpResponse::Ok()
                            .header(SERVER, HeaderValue::from_static("N"))
                            .header(CONTENT_TYPE, HeaderValue::from_static("application/json"))
                            .body(body.freeze()))
                    }),
            ),
            "/update" => Box::pin(
                self.0
                    .update(utils::get_query_param(req.uri().query()))
                    .map(|worlds| {
                        let mut body = BytesMut::with_capacity(35 * worlds.len());
                        let _ = simd_json::to_writer(crate::utils::Writer(&mut body), &worlds);
                        Ok(HttpResponse::Ok()
                            .header(SERVER, HeaderValue::from_static("N"))
                            .header(CONTENT_TYPE, HeaderValue::from_static("application/json"))
                            .body(body.freeze()))
                    }),
            ),
            _ => Box::pin(ok(Response::new(http::StatusCode::NOT_FOUND))),
        }
    }
}

struct AppFactory;

impl ServiceFactory<Request> for AppFactory {
    type Response = Response;
    type Error = Error;
    type Service = App;
    type InitError = ();
    type Future = Pin<Box<dyn Future<Output = Result<Self::Service, Self::InitError>>>>;

    fn new_service(&self, _: ()) -> Self::Future {
        const DB_URL: &str =
            "postgres://benchmarkdbuser:benchmarkdbpass@tfb-database/hello_world";

        Box::pin(async move { Ok(App(db::PgConnection::connect(DB_URL).await)) })
    }
}

#[ntex::main]
async fn main() -> std::io::Result<()> {
    println!("Starting http server: 127.0.0.1:8080");

    ntex::server::build()
        .backlog(1024)
        .bind("techempower", "0.0.0.0:8080", |cfg| {
            cfg.memory_pool(PoolId::P1);
            PoolId::P1.set_read_params(65535, 1024);
            PoolId::P1.set_write_params(65535, 1024);

            HttpService::build()
                .keep_alive(KeepAlive::Os)
                .client_timeout(Seconds(0))
                .h1(AppFactory)
        })?
        .run()
        .await
}
