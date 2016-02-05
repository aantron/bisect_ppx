## Release checklist

- Check the Travis log from the latest build(s) and make sure nothing strange is
  happening, such as errors or warnings that did not result in a command exiting
  with nonzero status.
- Pick a version number according to [semantic versioning][semver].
- Update the `CHANGES` file.
- `grep` for the previous version number. Replace occurences with the new
  version number. This should include `META`, `opam`, `version.ml`, and
  `README.md`,
- Tag (`tag -a`) the release and push the tag.
- Submit the release to OPAM.
- After release is accepted in OPAM, make a GitHub release for it as well. List
  the changes there. The reason this is done after OPAM is that the OPAM release
  may have to be amended before it is accepted.
- Update GitHub Pages.

[semver]: http://semver.org/
