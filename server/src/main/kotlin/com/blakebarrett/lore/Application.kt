package com.blakebarrett.lore

import io.ktor.application.*
import io.ktor.auth.*
import io.ktor.features.ContentNegotiation
import io.ktor.http.HttpStatusCode
import io.ktor.http.content.*
import io.ktor.routing.*
import io.ktor.serialization.*
import io.ktor.server.engine.embeddedServer
import io.ktor.server.netty.Netty
import io.ktor.sessions.*
import kotlinx.serialization.Serializable
import java.util.concurrent.ConcurrentHashMap

data class Artifact(val id: String, val content: String)

@Serializable
data class Comment(val id: String, val artifactId: String, val content: String)

val artifacts = ConcurrentHashMap<String, Artifact>()
val comments = ConcurrentHashMap<String, MutableList<Comment>>()

fun Application.module() {
    install(ContentNegotiation) {
        json()
    }

    install(StatusPages) {
        exception<Throwable> { cause ->
            call.respond(HttpStatusCode.InternalServerError, cause.localizedMessage)
        }
    }

    install(Authentication) {
        oauth("firebase-oauth") {
            // Configure OAuth settings for Firebase
            // ...
        }
    }

    routing {
        authenticate("firebase-oauth") {
            route("/artifacts/{id}") {
                get {
                    val id = call.parameters["id"] ?: return@get call.respond(HttpStatusCode.BadRequest, "Missing ID")
                    val artifact = artifacts[id] ?: return@get call.respond(HttpStatusCode.NotFound, "Artifact not found")
                    call.respond(artifact)
                }
            }

            route("/comments/{id}") {
                get {
                    val artifactId = call.parameters["id"] ?: return@get call.respond(HttpStatusCode.BadRequest, "Missing ID")
                    val artifactComments = comments[artifactId] ?: emptyList()
                    call.respond(artifactComments)
                }

                post {
                    val artifactId = call.parameters["id"] ?: return@post call.respond(HttpStatusCode.BadRequest, "Missing ID")
                    val comment = call.receive<Comment>()

                    comments.computeIfAbsent(artifactId) { mutableListOf() }.add(comment)

                    call.respond(HttpStatusCode.Created)
                }
            }
        }
    }
}

fun main() {
    embeddedServer(Netty, port = 8080, module = Application::module).start(wait = true)
}
