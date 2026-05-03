'use strict';

module.exports = {
  testEnvironment: 'node',
  coverageDirectory: 'coverage',
  collectCoverageFrom: [
    'server.js',
    'config.js',
    '!**/node_modules/**',
  ],
  testMatch: ['**/tests/**/*.test.js'],
};
