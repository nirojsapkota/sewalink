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

    ALL_TOOLS = [CREATE_TASK_DRAFT, PUBLISH_TASK, QUERY_TASKS].freeze
  end
end
