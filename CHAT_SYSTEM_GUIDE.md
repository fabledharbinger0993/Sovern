# Chat System Guide: Message Management & Conversation Flow

## Overview

The **Chat System** is the conversation interface—where users interact with Sovern and receive responses. Unlike a simple message log, ChatManager is a sophisticated conversation manager that maintains message history, links to Logic and Memory records, tracks statistics, and enables rich interactions (copying, searching, exporting).

**Key Principle**: Every message in Chat is linked to corresponding records in Logic (Congress debate) and Memory (learning). The chat window is the visible tip of three interconnected systems.

---

## Data Model: `ChatMessage`

```swift
struct ChatMessage: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let role: ChatRole              // user | assistant
    let content: String
    
    // Linked records
    let logicEntryId: UUID?         // Links to Congress debate
    let memoryEntryId: UUID?        // Links to learning record
    
    // Metadata
    let tokens: Int                 // Token count for usage tracking
    let isTyping: Bool              // Is this message being generated?
}
```

### Properties

| Property | Purpose | Notes |
|----------|---------|-------|
| `id` | Unique message ID | UUID generated at creation |
| `timestamp` | When message was sent/received | Matches Logic/Memory timestamps |
| `role` | Who sent it | user or assistant (Sovern) |
| `content` | Message text | Full user query or Sovern response |
| `logicEntryId` | Link to Congress | Only Sovern messages (user messages trigger Logic) |
| `memoryEntryId` | Link to learning | Only Sovern messages (user messages trigger Memory) |
| `tokens` | OpenAI token count | For usage/cost tracking |
| `isTyping` | Message being generated? | For typing indicator UI |

### ChatRole Enum

```swift
enum ChatRole: String, Codable {
    case user       // The human asking questions
    case assistant  // Sovern answering
}
```

Each role has:
- ✨ **emoji**: Display icon (👤 for user, 🤖 for Sovern)
- **displayName**: "You" or "Sovern" for UI

---

## ChatManager: Conversation Manager

```swift
class ChatManager: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isWaitingForResponse: Bool = false
}
```

### Core Operations

#### Add Messages

```swift
let userMsg = manager.addUserMessage("How do I handle conflict?")

manager.startTyping()                              // Start typing indicator
manager.updateTypingMessage("Typing response...")  // Update content
manager.finishTyping(logicEntryId: logicId, memoryEntryId: memoryId, tokens: 150)
```

Or:

```swift
manager.addSovernMessage(
    "Here's what I think...",
    logicEntryId: logicId,
    memoryEntryId: memoryId,
    tokens: 150
)
```

#### Link Records

After creating a LogicEntry or MemoryEntry, link the message:

```swift
manager.linkToLogic(messageId: chatMessageId, logicId: logicEntryId)
manager.linkToMemory(messageId: chatMessageId, memoryId: memoryEntryId)
```

#### Query Messages

```swift
manager.userMessages()                    // All user messages
manager.sovernMessages()                  // All Sovern responses
manager.messages(from: start, to: end)    // Time-range query
manager.mostRecentUserMessage             // Last question
manager.mostRecentSovernMessage           // Last response
manager.messagesWithLogicEntries()        // Messages with Congress debate linked
manager.messagesWithMemoryEntries()       // Messages with learning linked
manager.fullyLinkedMessages               // Both Logic and Memory linked
```

#### Search

```swift
let results = manager.search(for: "relationship")
let excerpt = manager.conversationExcerpt(around: messageId, contextSize: 2)
```

---

## Copy Functions: User-Friendly Export

### Single Message Copy

```swift
// Copy with formatting (role, emoji, timestamp, content)
if let formatted = manager.copyMessage(withId: messageId) {
    UIPasteboard.general.string = formatted
}

// Output:
// 👤 You [Feb 21, 2026, 10:30 AM]
// 
// How do I handle conflict in my relationship?
```

### Entire Conversation Copy

```swift
let fullConversation = manager.copyConversation()
UIPasteboard.general.string = fullConversation
```

Output:
```
👤 You [Feb 21, 2026, 10:30 AM]

How do I handle conflict in my relationship?

🤖 Sovern [Feb 21, 2026, 10:31 AM]

Conflict is an opportunity for deeper understanding...

👤 You [Feb 21, 2026, 10:35 AM]

But what if they won't listen?
```

### User Questions Only

```swift
let justQuestions = manager.copyUserMessages()
UIPasteboard.general.string = justQuestions
```

### Conversation as JSON

```swift
if let json = manager.copyConversationAsJSON() {
    UIPasteboard.general.string = json
    // Useful for exporting to files, sharing with backend, etc.
}
```

---

## Statistics Tracking

```swift
let stats = manager.statistics

stats.totalMessages              // Total messages sent
stats.userMessages               // User questions
stats.sovernMessages             // Sovern responses
stats.averageMessageLength       // Avg characters per message
stats.averageUserMessageLength   // Avg characters in questions
stats.averageSovernMessageLength // Avg characters in responses
stats.conversationTurns          // Number of user messages (conversation depth)
stats.conversationTimeSpan       // Total time span in seconds
stats.totalTokens                // Total OpenAI tokens used
stats.fullyLinkedMessages        // Messages with both Logic and Memory
stats.unlinkedLogicMessages      // Sovern responses missing Logic link
stats.unlinkedMemoryMessages     // Sovern responses missing Memory link
```

### Example: Conversation Health Check

```swift
let stats = manager.statistics

// All responses should be linked to Logic and Memory
if stats.unlinkedLogicMessages > 0 {
    print("Warning: \(stats.unlinkedLogicMessages) responses missing Logic link")
}

if stats.unlinkedMemoryMessages > 0 {
    print("Warning: \(stats.unlinkedMemoryMessages) responses missing Memory link")
}

// Conversation quality metrics
let avgTurns = Double(stats.conversationTurns)
let avgTokensPerTurn = Double(stats.totalTokens) / max(1, avgTurns)
print("Avg tokens per conversation turn: \(avgTokensPerTurn)")
```

---

## Typing Indicator Workflow

### For Streaming Responses

```swift
// Start showing typing indicator
chatManager.startTyping()

// Simulate streaming chunks
for chunk in responseStream {
    chatManager.updateTypingMessage(currentFullContent)
}

// Finalize the message
chatManager.finishTyping(
    logicEntryId: logicEntry.id,
    memoryEntryId: memoryEntry.id,
    tokens: finalTokenCount
)
```

### In SwiftUI View

```swift
var body: some View {
    ScrollView {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(chatManager.messages) { message in
                if message.role == .user {
                    // User message bubble
                    HStack {
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(message.content)
                            Text(message.timestamp.formatted(time: .shortened))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                } else {
                    // Sovern message bubble
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            if message.isTyping {
                                HStack(spacing: 4) {
                                    Circle().fill(Color.gray)
                                        .frame(width: 8)
                                    Circle().fill(Color.gray)
                                        .frame(width: 8)
                                        .opacity(0.6)
                                    Circle().fill(Color.gray)
                                        .frame(width: 8)
                                        .opacity(0.3)
                                }
                                .padding()
                            } else {
                                Text(message.content)
                                
                                // Copy button
                                Button(action: {
                                    if let formatted = chatManager.copyMessage(withId: message.id) {
                                        UIPasteboard.general.string = formatted
                                    }
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "doc.on.doc")
                                        Text("Copy")
                                    }
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        Spacer()
                    }
                }
            }
        }
        .padding()
    }
}
```

---

## Conversation Workflow

### Step 1: User Sends Message

```swift
let userMessage = chatManager.addUserMessage(userInput)
```

### Step 2: Start Typing Indicator

```swift
chatManager.startTyping()
```

### Step 3: Call Paradigm/Congress

```
(In background)
- Paradigm determines weight
- Congress engages (or routes directly)
- LogicEntry created with full debate
- Memory analysis extracts insights
- MemoryEntry created
```

### Step 4: Stream Response with Updates

```swift
for chunk in responseStream {
    let accumulated = previousContent + chunk
    chatManager.updateTypingMessage(accumulated)
}
```

### Step 5: Finalize Message with Links

```swift
chatManager.finishTyping(
    logicEntryId: logicEntry.id,
    memoryEntryId: memoryEntry.id,
    tokens: totalTokens
)
```

---

## Copy Function Usage Examples

### Example 1: Copy Button at Bottom of Message

```swift
HStack(spacing: 8) {
    Text(message.content)
    Spacer()
    
    Button(action: {
        if let content = chatManager.copyMessage(withId: message.id) {
            UIPasteboard.general.string = content
            // Show toast: "Copied!"
        }
    }) {
        Image(systemName: "doc.on.doc")
            .foregroundColor(.secondary)
    }
}
```

### Example 2: Export Entire Conversation

```swift
Button("Export Conversation") {
    let fullText = chatManager.copyConversation()
    // Share sheet
    let activity = UIActivityViewController(activityItems: [fullText], applicationActivities: nil)
    UIApplication.shared.windows.first?.rootViewController?.present(activity, animated: true)
}
```

### Example 3: Copy to External Service

```swift
Button("Send to Notes") {
    if let json = chatManager.copyConversationAsJSON() {
        // POST to backend or save to Files
    }
}
```

---

## Testing Examples

### Test Case 1: Message Creation

```swift
func testMessageCreation() {
    let message = ChatMessage(role: .user, content: "Hello Sovern")
    
    XCTAssertEqual(message.role, .user)
    XCTAssertEqual(message.content, "Hello Sovern")
    XCTAssertFalse(message.isUserMessage == false)  // Is user message
    XCTAssertTrue(message.isSovernMessage == false) // Not Sovern
    XCTAssertEqual(message.characterCount, 13)
}
```

### Test Case 2: ChatManager Operations

```swift
func testChatManagerBasics() {
    let manager = ChatManager()
    
    let user = manager.addUserMessage("How are you?")
    let sovern = manager.addSovernMessage("I'm well, thank you!")
    
    XCTAssertEqual(manager.messageCount, 2)
    XCTAssertEqual(manager.userMessageCount, 1)
    XCTAssertEqual(manager.sovernMessageCount, 1)
    XCTAssertEqual(manager.mostRecentUserMessage?.id, user.id)
    XCTAssertEqual(manager.mostRecentSovernMessage?.id, sovern.id)
}
```

### Test Case 3: Typing Indicator

```swift
func testTypingWorkflow() {
    let manager = ChatManager()
    
    manager.startTyping()
    XCTAssertTrue(manager.isWaitingForResponse)
    XCTAssertEqual(manager.sovernMessages().count, 1)
    XCTAssertTrue(manager.sovernMessages()[0].isTyping)
    
    manager.updateTypingMessage("Hello")
    XCTAssertEqual(manager.sovernMessages()[0].content, "Hello")
    
    manager.finishTyping()
    XCTAssertFalse(manager.sovernMessages()[0].isTyping)
    XCTAssertFalse(manager.isWaitingForResponse)
}
```

### Test Case 4: Copy Functions

```swift
func testCopyFunctions() {
    let manager = ChatManager()
    
    manager.addUserMessage("Test question")
    manager.addSovernMessage("Test response")
    
    let conversation = manager.copyConversation()
    XCTAssertTrue(conversation.contains("Test question"))
    XCTAssertTrue(conversation.contains("Test response"))
    
    let userOnly = manager.copyUserMessages()
    XCTAssertTrue(userOnly.contains("Test question"))
    XCTAssertFalse(userOnly.contains("Test response"))
}
```

### Test Case 5: Linking Logic & Memory

```swift
func testMessageLinking() {
    let manager = ChatManager()
    let msg = manager.addSovernMessage("Response")
    let logicId = UUID()
    let memoryId = UUID()
    
    manager.linkToLogic(messageId: msg.id, logicId: logicId)
    manager.linkToMemory(messageId: msg.id, memoryId: memoryId)
    
    let linked = manager.message(withId: msg.id)
    XCTAssertEqual(linked?.logicEntryId, logicId)
    XCTAssertEqual(linked?.memoryEntryId, memoryId)
}
```

---

## Backend Synchronization

| iOS Property | Python Field | Direction |
|--------------|--------------|-----------|
| `messages` | `conversation_history` | iOS → Python |
| `messageCount` | `interaction_count` | iOS → Python |
| `logicEntryId` (per message) | `logic_links` | iOS → Python |
| `memoryEntryId` (per message) | `memory_links` | iOS → Python |

---

## Key Patterns

✅ **Dual Linking**: Every Sovern message links to both Logic (debate) and Memory (learning)  
✅ **Timestamped Auditability**: All messages timestamped for cross-system synchronization  
✅ **User-Friendly Export**: Multiple copy formats (formatted, plain, JSON)  
✅ **Statistics Tracking**: Conversation health metrics and usage data  
✅ **Typing Indicator**: Real-time streaming response feedback  
✅ **Searchable History**: Full conversation searchable and exportable  

---

## Next Steps: Integration

1. **ChatView** will use ChatManager to display and manage message history
2. **Paradigm Router** will create LogicEntry and set weight
3. **Congress** will create entries linked to LogicEntry
4. **Memory** will create MemoryEntry and extract insights
5. **Message linking** will connect all three systems
6. **Chat exports** will enable users to share conversations or back them up
