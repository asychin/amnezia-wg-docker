## 📋 Description

<!-- Brief description of what this PR does -->

## 🔗 Related Issues

<!-- Links to issues this PR resolves -->
Fixes #(issue_number)

## 📊 Type of Changes

<!-- Put an x in the appropriate boxes -->

- [ ] 🐛 Bug fix (non-breaking change)
- [ ] ✨ New feature (non-breaking change)
- [ ] 💥 Breaking change (fix or feature that breaks compatibility)
- [ ] 📝 Documentation update
- [ ] 🔧 CI/CD changes
- [ ] 🏗️ Code refactoring
- [ ] ⚡ Performance improvement
- [ ] 🧪 Adding/updating tests

## 🧪 Testing

<!-- Describe how you tested your changes -->

### Testing Environment
- [ ] Docker version: <!-- e.g., 24.0.7 -->
- [ ] OS: <!-- e.g., Ubuntu 22.04 -->
- [ ] Architecture: <!-- e.g., AMD64, ARM64 -->

### Tests Performed
- [ ] Docker image builds without errors
- [ ] Container starts correctly
- [ ] Healthcheck works
- [ ] Core functionality tested
- [ ] New features tested

### Testing Commands
```bash
# Specify commands used for testing
make build
make up
make test
```

## 📝 Checklist

### General Requirements
- [ ] My code follows the project's style guidelines
- [ ] I have performed a self-review of my code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have updated documentation as needed
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix/feature works

### Docker-specific Requirements
- [ ] Dockerfile is optimized (multi-stage build, minimal layers)
- [ ] Docker image builds without warnings
- [ ] Image size hasn't increased significantly
- [ ] Image works correctly on different architectures (if applicable)

### CI/CD Requirements
- [ ] All automated checks pass
- [ ] New GitHub Actions workflows are tested
- [ ] Secrets and environment variables are documented

## 📊 Performance Impact

<!-- If applicable, describe performance impact -->

- [ ] No performance impact
- [ ] Improves performance
- [ ] May negatively impact performance (explain below)

## 🔒 Security Considerations

<!-- If applicable, describe security impact -->

- [ ] No security impact
- [ ] Improves security
- [ ] May negatively impact security (explain below)

## 📸 Screenshots/Logs

<!-- If applicable, add screenshots or logs -->

<details>
<summary>Build Logs</summary>

```
Paste logs here
```

</details>

## 🔄 Breaking Changes

<!-- If there are breaking changes, describe them in detail -->

### What Changed
<!-- List of breaking changes -->

### Migration Guide
<!-- Instructions for users to migrate -->

## 📚 Additional Notes

<!-- Any additional information for reviewers -->

## 🏷️ Versioning

<!-- If applicable -->
- [ ] This is a patch release (x.x.X)
- [ ] This is a minor release (x.X.x)
- [ ] This is a major release (X.x.x)

---

### 🔍 For Reviewers

<!-- Information for those who will review the PR -->

#### Key Areas to Review
<!-- Specify what to pay special attention to -->

#### Testing
```bash
# Commands for quick PR testing
git checkout <branch>
make build
make up
make test
```

---

**Thank you for contributing to AmneziaWG Docker Server! 🎉**