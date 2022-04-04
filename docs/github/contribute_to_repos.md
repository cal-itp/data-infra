# Contributing to data services repos

These guidelines are meant to provide a foundation for collaboration in Cal-ITP's data services repos (primarily [#data-infra](https://github.com/cal-itp/data-infra).)

## Issues:
* When submitting an issue, please make it clear what the acceptance criteria are; i.e., what is sufficient to consider a fix “done” for the issue. The purpose of this expectation is to ensure that issues represent actionable pieces of work that can be accurately prioritized and assigned for resolution.
    * For example: The following issue is vague and could fall victim to an unhelpful cycle of swirl and scope creep:
      > Add best practices to reports

    * The following issue is clearer. If scope were to increase (for example, the author realizes that they also want a chart), it would be clearer that that should be created as a new, follow-up request.
       > Add a new section to reports called ‘Best Practices Violations’. It should be inserted immediately after and appear just like the existing critical validation errors table and include validation notices W1, W2, and W3.

   * If you have a request that you want help scoping before submitting as an issue, posting on the Cal-ITP Slack (for example in the `#data-infra`, `#data`, or `#gtfs-quality` channels, depending on the nature of the request) is one way to ask for assistance. Depending on the size of the request, a Slack conversation may be enough to scope it sufficiently. For large requests, a meeting or larger design process may be needed before submission.

* When closing an issue without a merged PR, please indicate one of the following (they provide a paper trail for reporting and indicate lessons learned):
   * What non-PR actions were taken to resolve the issue
   * Why no action is necessary
   * Why it is no longer an issue at this time


## Working on Branches & Creating Pull Requests:


* Organize your work into [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/).
* Commit and push early and often for team visibility.
* Split up a large PR if it’s getting too big (code reviews should ideally take no more than 10 minutes).
* PR description is required and should document the purpose of the PR in a way that someone who was not involved at the time can understand later.
   * For example, the following description is not sufficient as persistent PR documentation (though it may be sufficient very temporarily while a critical fix is in flight with multiple people collaborating closely and reviewing each others' work).
      > Hotfix - type2
   * The persistent description should generally be at least as detailed as:
      > Hotfix for issue where merge_updates.py throws a MadeUpError exception on files containing the number 7 (issue was identified on ITP ID 1 URL 1, feed_info file extracted on 2022-03-22).
      Fix was to add a try/except block to catch the number 7 and cast it to string before running the merge SQL. More investigation information is documented in [link to Slack thread].


* PRs should be linked to any issues that they close. [Keywords](https://docs.github.com/en/issues/tracking-your-work-with-issues/linking-a-pull-request-to-an-issue#linking-a-pull-request-to-an-issue-using-a-keyword) are one good way to do this.


## Code Reviews - PR Author:


* All PRs should get one approving review before being merged.
* Move your PR out of draft status when it’s ready for review and merging.
* Maintain responsibility for all PRs you open until they are merged, keeping an eye out for comments and merging promptly after approval is received.
* PR authors should merge PRs once approval is received.


## Code Reviews - Reviewer:
* Google provides a [How to do a code review reference](https://google.github.io/eng-practices/review/reviewer/) that reviewers may find helpful.
* Reviewers should not submit comments on PRs that are still in draft status unless specifically requested by the PR author.
* Reviewers should be explicit about the intention of their comments and what type of response is required. [Conventional comments](https://conventionalcomments.org/) are one way to make it clear to recipients of review what notes require what action and what’s just feedback.
* If you are approving a PR and leave a comment with your approval, the PR author should understand that that comment is **optional** to address.
   * If you have a change that you think should be **required** before the change is merged, please request changes on the PR rather than approving.
* When your review is requested, you should submit a review within 2 business days.
   * Recommendation: You can configure [GitHub's Scheduled Reminders](https://github.com/settings/reminders) to send you through Slack a list of review requests assigned to you near the start of your regular workdays.
* Reviewers should not generally merge PRs themselves and should instead let the author merge, since authors will have the most context about merge considerations (for example, whether additional reviews are still needed, or whether any communication is needed about the impacts of the PR when it merges).
   * The main exception is changes to `agencies.yml`. Reviewers are encouraged to merge changes to `agencies.yml` as soon as their approving review is complete since these changes are usually time-sensitive to make sure data is scraped (and these changes are usually not risky from a code perspective).


## General:
* Keep conversations in GitHub when possible, and expect that people will see them when you tag them.
