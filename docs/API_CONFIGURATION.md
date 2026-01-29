# API Configuration Guide

## Unsplash API Configuration

The app uses the Unsplash API to fetch random images for puzzles. You can run the app without configuring this (it will use fallback images)



## Getting an Unsplash API Key

1. Go to [Unsplash Developers](https://unsplash.com/developers)
2. Sign up or log in
3. Create a new application
4. Copy your "Access Key"
5. Use it in one of the configuration methods above

## Testing Without an API Key

The app will automatically fall back to local placeholder images if no API key is configured. This is useful for:

- Testing the app without setting up an API key
- Running in environments where the API is unavailable
- CI/CD pipelines

## Production Deployment

For production apps, consider:

1. **Backend Proxy**: Create a backend service that makes API calls on behalf of your app
2. **Key Rotation**: Regularly rotate API keys
3. **Rate Limiting**: Implement proper rate limiting to avoid API quota exhaustion
4. **Monitoring**: Monitor API usage and errors

## Troubleshooting

If images aren't loading:

1. Check that your API key is correctly configured
2. Verify the key is valid on the Unsplash dashboard
3. Check the debug console for error messages
4. Ensure you haven't exceeded your API rate limit
5. Verify internet connectivity

The app will log helpful messages in debug mode to help diagnose issues.
