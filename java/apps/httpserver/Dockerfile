FROM gradle:7.6.1-jdk17 AS build
COPY --chown=gradle:gradle . /home/gradle/src
WORKDIR /home/gradle/src
RUN gradle clean build --no-daemon

FROM amazoncorretto:17
EXPOSE 8080
RUN mkdir /app
COPY --from=build /home/gradle/src/build/libs/httpserver-java.jar /app/httpserver-java.jar
ENTRYPOINT ["java","-jar","/app/httpserver-java.jar"]
