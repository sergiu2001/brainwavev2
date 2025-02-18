module.exports = {
  root: true,
  env: {
    es6: true,
    node: true,
  },
  extends: [
    "eslint:recommended",
    "plugin:import/errors",
    "plugin:import/warnings",
    "plugin:import/typescript",
    "google",
  ],
  parser: "@typescript-eslint/parser",
  parserOptions: {
    project: ["tsconfig.json", "tsconfig.dev.json"],
    sourceType: "module",
  },
  ignorePatterns: [
    "/lib/**/*", // Ignore built files
  ],
  plugins: ["@typescript-eslint", "import"],
  rules: {
    // Add these rules to relax restrictions
    "quotes": ["error", "double"],
    "max-len": ["error", { "code": 120 }],
    "indent": ["error", 2],
    "object-curly-spacing": ["error", "always"],
    "comma-dangle": ["error", "only-multiline"],
    "require-jsdoc": 0,
    "no-unused-vars": 0
  },
};