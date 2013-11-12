package com.surevine.nexus.securitylabels;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.inject.Named;
import javax.inject.Singleton;

import org.restlet.Context;
import org.restlet.data.MediaType;
import org.restlet.data.Request;
import org.restlet.data.Response;
import org.restlet.resource.ResourceException;
import org.restlet.resource.Variant;
import org.sonatype.plexus.rest.resource.AbstractPlexusResource;
import org.sonatype.plexus.rest.resource.PathProtectionDescriptor;
import org.sonatype.plexus.rest.resource.PlexusResource;

@Named
@Singleton
public class SecurityMetadataResource extends AbstractPlexusResource implements PlexusResource {

	public SecurityMetadataResource() {
		setReadable(true);
		
		setModifiable(true);
	}

	@Override
	public List<Variant> getVariants() {
		final List<Variant> variants = new ArrayList<Variant>(1);
		
		variants.add(new Variant(MediaType.APPLICATION_JSON));
		
		return variants;
	}

	@Override
	public Object getPayloadInstance() {
		return null;
	}

	@Override
	public PathProtectionDescriptor getResourceProtection() {
		return new PathProtectionDescriptor(this.getResourceUri(), "authcBasic");
	}

	@Override
	public String getResourceUri() {
		return "/emetadata/{repository}/{subject}";
	}

	@Override
	public Object get(Context context, Request request, Response response, Variant variant)
			throws ResourceException {
		final Map<String, String> properties = new HashMap<String, String>();
		
		// TODO: Pull from file

		properties.put("repository", String.valueOf(request.getAttributes().get("repository")));
		properties.put("subject", String.valueOf(request.getAttributes().get("subject")));

		properties.put("classification", "COMMERCIAL");
		properties.put("decorator", "IN CONFIDENCE");
		properties.put("groups", "STAFF");
		properties.put("countries", "UK");
		
		return properties;
	}

	@Override
	public Object post(Context context, Request request, Response response,
			Object payload) throws ResourceException {
		// TODO Auto-generated method stub
		return super.post(context, request, response, payload);
		
		// TODO: Push to file
	}

	@Override
	public Object put(Context context, Request request, Response response,
			Object payload) throws ResourceException {
		// TODO Auto-generated method stub
		return super.put(context, request, response, payload);
	}
	
	
}
