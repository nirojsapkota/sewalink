module Gemini
  module ToolDefinitions
    CREATE_TASK_DRAFT = {
      name: "create_task_draft",
      description: "Create or update a draft task for a service needed by the user. Call this IMMEDIATELY whenever the user provides or changes details like title, description, budget, or location to ensure the UI preview is updated.",
      parameters: {
        type: "OBJECT",
        properties: {
          title: {
            type: "STRING",
            description: "A concise title for the task (e.g., 'Fix leaky faucet', 'Mathematics tutoring')"
          },
          description: {
            type: "STRING",
            description: "A detailed description of the work required."
          },
          budget: {
            type: "NUMBER",
            description: "The estimated budget in Nepalese Rupees (NPR)."
          },
          location: {
            type: "STRING",
            description: "The physical location or neighborhood where the task is needed."
          }
        },
        required: ["title", "description"]
      }
    }.freeze

    PUBLISH_TASK = {
      name: "publish_task",
      description: "Finalize and publish the user's current draft task so it becomes visible to taskers. Call this ONLY when the user explicitly asks to 'publish', 'post', or 'finish' their task.",
      parameters: {
        type: "OBJECT",
        properties: {},
        required: []
      }
    }.freeze

    QUERY_TASKS = {
      name: "query_tasks",
      description: "Get a summary of the user's tasks, their statuses, and counts. Use this to answer questions like 'How many tasks do I have pending?' or 'What is the status of my plumbing task?'. It returns information based on the user's active role (Poster or Tasker).",
      parameters: {
        type: "OBJECT",
        properties: {
          search_query: {
            type: "STRING",
            description: "Optional keywords to filter tasks by title or description."
          }
        }
      }
    }.freeze

    SEARCH_KNOWLEDGE_BASE = {
      name: "search_knowledge_base",
      description: "Answer general how-to, policy, or FAQ style questions about how the SewaLink " \
        "platform itself works (e.g. escrow/payments, commission, safety/geofencing, disputes, " \
        "reviews, account security, admin settings) by searching SewaLink's official knowledge " \
        "base. Only call this when the user's message contains an explicit trigger keyword such " \
        "as 'help', 'faq', 'guide', or 'policy' (e.g. 'Can you help me understand how escrow " \
        "works?'). Do NOT call this for questions about the user's own tasks/bids (use " \
        "query_tasks instead) or while creating/publishing a task.",
      parameters: {
        type: "OBJECT",
        properties: {
          query: {
            type: "STRING",
            description: "The user's question, verbatim or lightly cleaned up, to search the knowledge base with."
          }
        },
        required: ["query"]
      }
    }.freeze

    # Backend guard (see Gemini::ToolsController#execute): search_knowledge_base is only
    # actually invoked when the query contains one of these trigger keywords, so a Bedrock
    # call isn't made for every message just because the LLM decided to call the tool.
    KNOWLEDGE_BASE_TRIGGER_KEYWORDS = %w[help faq guide guidance policy].freeze

    ALL_TOOLS = [CREATE_TASK_DRAFT, PUBLISH_TASK, QUERY_TASKS, SEARCH_KNOWLEDGE_BASE].freeze
  end
end
