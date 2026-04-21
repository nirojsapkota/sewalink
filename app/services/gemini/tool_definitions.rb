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

    ALL_TOOLS = [CREATE_TASK_DRAFT, PUBLISH_TASK].freeze
  end
end
