package com.example.springboot;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {

	@Value("${spring.application.name}")
    private String appName;

	@Value("${git.branch}")
    private String branch;

    @Value("${git.commit.id.full}")
    private String commitId;

	@GetMapping("/")
	public String index() {
		return "Greetings from Spring Boot!";
	}

	@GetMapping("get-app-name")
    public String getAppName() {
        return appName;
    } 

    @RequestMapping("/get-app-build-version")
    public String getAppBuildVersion() {
        return branch + "-" + commitId;
    }
}
