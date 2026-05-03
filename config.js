'use strict';

/**
 * Centralised application configuration.
 *
 * All environment-specific values are read here. The rest of the codebase
 * imports this module instead of reading process.env directly — that way
 * there is exactly one place to look when you wonder "what settings does
 * this app have?"
 */
const config = {
  port: parseInt(process.env.PORT, 10) || 3000,
  nodeEnv: process.env.NODE_ENV || 'development',

  // Convenience booleans
  isDev:  (process.env.NODE_ENV || 'development') === 'development',
  isProd: process.env.NODE_ENV === 'production',
};

module.exports = config;
