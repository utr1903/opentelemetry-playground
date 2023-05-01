package com.newrelic.otelplayground.simulator.handlers;

import java.io.IOException;

import org.springframework.http.HttpStatus;
import org.springframework.http.client.ClientHttpResponse;
import org.springframework.web.client.ResponseErrorHandler;

public class RestTemplateResponseErrorHandler
		implements ResponseErrorHandler {

	@Override
	public boolean hasError(ClientHttpResponse httpResponse)
			throws IOException {
		return (httpResponse.getStatusCode() == HttpStatus.BAD_REQUEST
				|| httpResponse.getStatusCode() == HttpStatus.INTERNAL_SERVER_ERROR);
	}

	@Override
	public void handleError(ClientHttpResponse httpResponse)
			throws IOException {

		// if (httpResponse.getStatusCode().series() ==
		// HttpStatus.Series.SERVER_ERROR) {
		// // handle SERVER_ERROR
		// }
		// else if (httpResponse.getStatusCode().series() ==
		// HttpStatus.Series.CLIENT_ERROR) {
		// // handle CLIENT_ERROR
		// if (httpResponse.getStatusCode() == HttpStatus.NOT_FOUND) {
		//
		// }
		// }
	}
}