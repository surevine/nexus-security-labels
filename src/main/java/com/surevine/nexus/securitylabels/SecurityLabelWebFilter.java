package com.surevine.nexus.securitylabels;

import static com.google.common.base.Preconditions.checkNotNull;

import java.io.File;
import java.io.FilenameFilter;
import java.io.IOException;
import java.io.PrintWriter;
import java.nio.file.Path;
import java.nio.file.Paths;

import javax.inject.Inject;
import javax.inject.Singleton;
import javax.servlet.FilterChain;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.http.HttpStatus;
import org.apache.shiro.subject.Subject;
import org.apache.shiro.web.filter.mgt.FilterChainResolver;
import org.apache.shiro.web.mgt.WebSecurityManager;
import org.apache.shiro.web.servlet.AbstractShiroFilter;
import org.apache.shiro.web.servlet.ShiroFilter;
import org.sonatype.security.SecuritySystem;

/**
 * Injected {@link ShiroFilter}.
 */
@Singleton
public class SecurityLabelWebFilter extends AbstractShiroFilter {
	
	private static final String REPO_CONTEXT = "/nexus/service/local/repositories";

	@Inject
	protected SecurityLabelWebFilter(SecuritySystem securitySystem,
			FilterChainResolver filterChainResolver) {
		this.setSecurityManager((WebSecurityManager) checkNotNull(
				securitySystem.getSecurityManager(), "securityManager"));
		this.setFilterChainResolver(checkNotNull(filterChainResolver,
				"filterChainResolver"));
	}

	@Override
	protected void doFilterInternal(final ServletRequest req, final ServletResponse res, final FilterChain chain)
			throws ServletException, IOException {
		final HttpServletRequest request = (HttpServletRequest) req;
		final HttpServletResponse response = ((HttpServletResponse) res);
		
		final Subject subject = createSubject(req, res);
		final String root = System.getProperty("nexus-work") +"/storage";
		final String uri = request.getRequestURI();
		
		System.out.println(((HttpServletRequest) req).getMethod() +" : " +uri);
		
		if (uri.startsWith(REPO_CONTEXT)) {
			//FIXME: Only strip first /content/ in case someone has content in a groupId.
			Path path = Paths.get(root +uri.substring(REPO_CONTEXT.length()).replaceAll("/content/", "/"));
			if (path.toFile().isFile()) {
				path = path.getParent();
			}

			final String[] labels = path.toFile().list(new FilenameFilter() {
				@Override
				public boolean accept(final File dir, final String name) {
					if (name.endsWith("-securitylabel.xml")) {
						return true;
					}
					
					return false;
				}
			});
			
			// FIXME: Rather than ban all access where label and !admin, check
			//			label permissions properly.
			if (labels != null && labels.length > 0 && !"admin".equals(subject.getPrincipal().toString())) {
				System.out.println(String.format("Security label found for %s. Disallowing access to %s.",
						uri, subject.getPrincipal()));
				response.setStatus(HttpStatus.SC_NOT_FOUND);
				final PrintWriter writer = response.getWriter();
				writer.print("Not found.");
				writer.flush();
				writer.close();
				return;
			}
		}
		
		super.doFilterInternal(req, res, chain);
	}
}
