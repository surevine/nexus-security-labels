package com.surevine.nexus.securitylabels;

import java.util.logging.Logger;

import javax.inject.Named;

import com.google.inject.AbstractModule;
import com.google.inject.servlet.ServletModule;

@Named
public class SecurityLabelFilterModule extends AbstractModule {
	
	private static final Logger LOG = Logger.getLogger(SecurityLabelFilterModule.class.getName());

	@Override
	protected void configure() {
	    install(new ServletModule() {
	      @Override
	      protected void configureServlets() {
	    	  filter("/*").through(SecurityLabelWebFilter.class);
//	    	  filter("/service/local/repositories/*").through(SecurityLabelWebFilter.class);
	      }
	    });
	}
}
