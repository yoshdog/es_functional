In the [video](https://www.youtube.com/watch?v=kZL41SMXWdM) Greg Young explains event sourcing in a functional context. The main ideas are:

```ruby
# Commands

fn(state, command) -> events

# Processing an event

fn(state, event) -> state

# Get current state

reduce(initial_state, events, fn(state, event) -> pattern_match(event, fn(state, event) -> state))

```

This repo is me trying to implement a bank account app using these simple concepts.
