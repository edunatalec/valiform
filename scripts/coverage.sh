#!/bin/bash

echo "Running tests with coverage..."
flutter test --coverage

echo "Generating HTML report..."
genhtml -o coverage/html coverage/lcov.info

echo "✅ Coverage report generated successfully!"

open coverage/html/index.html
