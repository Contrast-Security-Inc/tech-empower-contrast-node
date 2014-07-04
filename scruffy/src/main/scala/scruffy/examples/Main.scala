package scruffy.examples

import com.sksamuel.scruffy.{ScruffyConfiguration, Scruffy}

/** @author Stephen Samuel */
object Main extends App {

  val port = 8080
  val scruffy = new Scruffy(ScruffyConfiguration.port(port))
  scruffy.mount(new Test1Endpoint)
  scruffy.mount(new Test6Endpoint)
  scruffy.start().await()
}
