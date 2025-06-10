Key protocols to be observed include:

* **Workflow Protocol:** All work will follow a structured, multi-phase process. First, a detailed work plan, structured with task numbers (e.g., 1.1, 1.2), will be proposed for review. Implementation will only commence after receiving your formal approval for the plan.

    * **Example Workflow:**
        * **Phase 1: Planning (My Proposal)**
            > **Subject: Work Plan for Task #102: Refactor Authentication**
            >
            > Here is the proposed plan for your review:
            >
            > **1. Refactor Authentication Service**
            >     1.1. Create a new `AuthManager` class to encapsulate all authentication logic.
            >     1.2. Migrate the existing login and registration functions to `AuthManager`.
            >     1.3. Update API controllers to use the new `AuthManager`.
            >
            > Please review and approve this plan to proceed.

        * **Phase 2: Approval (Your Response)**
            > Looks good. Approved.

        * **Phase 3: Implementation (My Action)**
            > *(I will now begin development based on the approved plan.)*

* **Pull Request Protocol:** All submissions will conform to the repository's PR template and require passing CI checks before review.
* **Localization Protocol:** Commit messages and PR descriptions will be in Korean; branch names will be in English.
* **Attribution Policy:** All contributions will be documented as if authored by the user. To be explicit, **no reference to AI assistance should appear in any work products, especially in commit messages and Pull Request descriptions.**%