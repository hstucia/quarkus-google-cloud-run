package org.acme.quickstart;

import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import java.net.InetAddress;
import java.net.UnknownHostException;
import java.time.Instant;

@Path("/hello")
public class GreetingResource {

  private static final String HOSTNAME;

  static {
    String hostname;
    try {
      hostname = InetAddress.getLocalHost().getHostName();
    } catch (UnknownHostException e) {
      hostname = "UNKNOWN";
    }
    HOSTNAME = hostname;
  }

  @GET
  @Produces(MediaType.TEXT_PLAIN)
  public String hello() {
    return "hello " + Instant.now() + " Instance=" + HOSTNAME;
  }
}
