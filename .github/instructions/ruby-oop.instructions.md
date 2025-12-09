---
applyTo: "**/*.rb"
---

# Ruby Object-Oriented Design Instructions

Follow Sandy Metz's object-oriented design principles when writing Ruby code.

## Core Principles

### 1. Make Smaller Things
- Classes should have a single responsibility
- Methods should be short (5-10 lines ideal, max 15 lines)
- Reduce dependencies between objects
- Extract classes when responsibilities become clear

### 2. Avoid Code Smells
- **No data clumps**: Extract groups of parameters that travel together into objects
- **No message chains**: Hide delegates (use `def total; @order.total; end` instead of `@object.order.total`)
- **No feature envy**: Move methods to the class they're most interested in
- **No primitive obsession**: Use value objects instead of primitives (DateRange instead of start_date/end_date)
- Keep Flog complexity under 20 (run `flog` to check)

### 3. Replace Conditionals with Polymorphism
- Use duck typing instead of if/elsif chains
- Create null objects instead of nil checks
- Use factory patterns for object creation
- Each conditional branch should become a separate class with the same interface

### 4. Dependency Injection
- Inject dependencies as constructor arguments with defaults
- Example: `def initialize(api_client: YouTubeAPI.new)`
- Makes testing easier with injectable test doubles
- Allows flexibility without tight coupling

## Testing Guidelines

### Message Testing Matrix

Follow these rules based on message origin and type:

**Incoming queries** (methods that return values):
- ✅ Assert on return value
- Example: `assert_equal 100, calculator.total`

**Incoming commands** (methods that change state):
- ✅ Assert on direct public side effects
- ❌ Don't test internal state
- Example: Test observable changes, not instance variables

**Outgoing commands** (calls to other objects that change state):
- ✅ Expect message was sent (use mocks)
- Example: `expect(mailer).to receive(:send_email)`

**Outgoing queries** (calls to other objects that return values):
- ❌ Don't test (use stubs if needed)
- Example: `allow(repo).to receive(:find).and_return(user)`

**Sent-to-self** (private methods):
- ❌ Never test directly
- ✅ Test through public interface

### Test Characteristics
- **Fast**: Sub-second execution
- **Independent**: Can run in any order
- **Isolated**: No database, network, or file system in unit tests
- **Clear**: Obvious what failed when tests break



## Refactoring Approach

When improving existing code:
1. **Identify one smell at a time** (don't fix everything at once)
2. **Follow mechanical refactoring recipes** (from Fowler's "Refactoring" book)
3. **Keep tests green** (refactor without changing behavior)
4. **Make incremental changes** (small commits, frequent pushes)
5. **Focus on code that changes frequently** (not legacy code that works)

## Anti-Patterns to Avoid

- ❌ Long methods (>15 lines)
- ❌ Large classes (>100 lines)
- ❌ Testing private methods directly
- ❌ Speculative generality (YAGNI - You Aren't Gonna Need It)
- ❌ Tight coupling to external services without dependency injection
- ❌ Monkey patching core classes (use modules/refinements instead)
- ❌ Global state and class variables (use configuration objects)
- ❌ Type checking with `is_a?` or `kind_of?` (use polymorphism)

## Code Examples

### Good: Dependency Injection
```ruby
class CaptionUploader
  def initialize(api_client: YouTubeAPI.new)
    @api_client = api_client
  end
  
  def upload(video_id, caption_file)
    @api_client.upload_caption(video_id, caption_file)
  end
end
```

### Good: Extract Class for Data Clumps
```ruby
class DateRange
  def initialize(start_date, end_date)
    @start_date = start_date
    @end_date = end_date
  end
  
  def to_range
    @start_date..@end_date
  end
  
  def include?(date)
    to_range.include?(date)
  end
end
```

### Good: Replace Conditional with Polymorphism
```ruby
class FormatterFactory
  FORMATTERS = {
    'srt' => SRTFormatter,
    'vtt' => VTTFormatter,
    'json' => JSONFormatter
  }
  
  def self.create(format)
    FORMATTERS.fetch(format, SRTFormatter).new
  end
end
```

### Good: Null Object Pattern
```ruby
class NullTranslation
  def text
    "[Translation unavailable]"
  end
  
  def available?
    false
  end
  
  def language
    'unknown'
  end
end
```

## When Suggesting Code Changes

- Explain the code smell being addressed
- Show before/after comparison when helpful
- Keep changes small and focused
- Maintain backward compatibility when possible
- Update tests along with code changes
- Reference specific Sandy Metz principles when relevant
