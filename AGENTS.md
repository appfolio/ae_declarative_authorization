# AGENTS.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview
ae_declarative_authorization is a Rails authorization gem that provides role-based access control (RBAC) with a declarative approach. Authorization rules are defined in `config/authorization_rules.rb` rather than scattered throughout controllers, views, and models.

## Core Architecture

### Main Components
- **Authorization Engine** (`lib/declarative_authorization/authorization.rb`): Reference monitor that evaluates permissions and enforces authorization rules. The `Engine` class is the central orchestrator.
- **DSL Reader** (`lib/declarative_authorization/reader.rb`): Parses authorization rules from the DSL configuration file. Key classes:
  - `DSLReader`: Top-level parser for authorization configuration
  - `AuthorizationRulesReader`: Parses role definitions and permission rules
  - `PrivilegesReader`: Handles privilege hierarchies
- **Controller Integration** (`lib/declarative_authorization/controller/`):
  - `dsl.rb`: Provides `filter_access_to` and `filter_resource_access` methods for controllers
  - `rails.rb`: Rails-specific controller integration
  - `grape.rb`: Grape API framework integration
- **Model Integration** (`lib/declarative_authorization/in_model.rb`): Enables model security with `using_access_control` and query rewriting via `with_permissions_to`
- **ObligationScope** (`lib/declarative_authorization/obligation_scope.rb`): Translates authorization obligations into SQL joins and conditions for efficient query rewriting
- **View Helpers** (`lib/declarative_authorization/helper.rb`): Provides `permitted_to?` and role checking helpers for views

### Authorization Flow
1. Request hits controller → `filter_access_to` or `filter_resource_access` intercepts
2. Engine evaluates user's roles against authorization rules from DSL
3. For attribute-based rules, loads object and checks conditions
4. Raises `Authorization::NotAuthorized` or `Authorization::AttributeAuthorizationError` on denial
5. For model queries, `ObligationScope` rewrites queries to only return authorized records

### Key Patterns
- **Thread-safe user storage**: `Authorization.current_user` uses `Thread.current` for model-level security
- **Privilege hierarchies**: E.g., `:manage` includes `:create`, `:read`, `:update`, `:delete`
- **Role hierarchies**: Roles can include other roles via `includes`
- **Attribute conditions**: Rules can check object attributes (e.g., `if_attribute :branch => is {user.branch}`)
- **Permission dependencies**: Rules can depend on permissions of associated objects via `if_permitted_to`

## Development Commands

### Running Tests
```bash
# Run all tests
rake test

# Run specific test file
ruby test/authorization_test.rb

# Run single test (using Minitest)
ruby test/authorization_test.rb -n test_name_here
```

### Testing Multiple Rails/Grape Versions
This gem uses Appraisal to test against multiple dependency combinations:
```bash
# Install all appraisal gemfiles
bundle exec appraisal install

# Run tests for all combinations
bundle exec appraisal rake test

# Run tests for specific combination
bundle exec appraisal ruby-2.7.5-rails_6.1-grape_1.6 rake test
```
Supported combinations are defined in `Appraisals` (Ruby 2.6.9, 2.7.5, 3.1.0 with various Rails and Grape versions).

### Building and Releasing
```bash
# Build gem
gem build declarative_authorization.gemspec

# Install locally for testing
gem install ae_declarative_authorization-*.gem

# Release (requires appropriate permissions)
bundle exec rake release
```

### Generating Documentation
```bash
rake rdoc
```
Documentation is generated to `rdoc/` directory.

## Testing Infrastructure
- Uses **Minitest** (not RSpec)
- Test helpers in `lib/declarative_authorization/test/helpers.rb` provide `with_user`, `without_access_control`, and HTTP verb helpers like `get_with`, `post_with`
- Mock objects in `test/test_helper.rb` (`MockUser`, `MockDataObject`)
- `test/test_support/` contains Rails and Grape test infrastructure

## Installation Generators
The gem provides Rails generators:
- `rails g authorization:install [UserModel]`: Sets up Role model, associations, and authorization rules
- `rails g authorization:rules`: Copies default authorization rules to `config/authorization_rules.rb`

## Important Configuration
- **Authorization rules file**: `config/authorization_rules.rb` (configurable via `Authorization::AUTH_DSL_FILES`)
- **Default role**: `:guest` (configurable via `Authorization.default_role=`)
- **Current user**: Controllers must implement `current_user` method
- **User role method**: User model must implement `role_symbols` returning array of role symbols

## Special Considerations
- This gem supports **Rails 4.2.5.2 through 7.0** and **Ruby >= 2.6.3**
- Model security is opt-in via `using_access_control` on individual models
- Read checks on models require explicit `:include_read => true` option due to performance implications
- `strong_parameters` integration is enabled by default for `filter_resource_access`
- The gem supports both Rails controllers and Grape APIs

## Common Patterns in Tests
- Use `Authorization::Engine.new(reader)` with custom DSL for isolated testing
- Access control can be globally disabled in tests via `Authorization.ignore_access_control`
- Create mock users with role symbols: `MockUser.new(:admin, :user => { :id => 1 })`
