package com.surevine.nexus.securitylabels;

import javax.inject.Named;

import com.google.inject.AbstractModule;
import com.google.inject.servlet.ServletModule;

@Named
public class SecurityLabelFilterModule extends AbstractModule {

	@Override
	protected void configure() {
	    install(new ServletModule() {
	      @Override
	      protected void configureServlets() {
	    	  filter("/service/local/repositories/*").through(SecurityLabelWebFilter.class);
	      }
	    });
	}
}
