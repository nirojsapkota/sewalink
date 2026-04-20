module Gemini
  module ToolDefinitions
    CREATE_TASK_DRAFT = {
      name: "create_task_draft",
      description: "Create a draft task for a service needed by the user. Call this when the user describes a job they want done.",
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

    ALL_TOOLS = [CREATE_TASK_DRAFT].freeze
  end
end
