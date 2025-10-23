# 🎓 Modular Certification Platform

> Stack verified micro-certificates into recognized degrees on the Stacks blockchain

## 📋 Overview

The Modular Certification Platform enables learners to collect and combine verified micro-credentials into stackable degrees recognized by DAOs and educational institutions. Built on Stacks using Clarity smart contracts, it provides immutable credential verification and transparent reputation tracking.

## ✨ Key Features

- 🏅 **Micro-Credential Issuance**: Authorized issuers can create verifiable credentials
- 📚 **Degree Stacking**: Combine multiple credentials into recognized degrees
- ✅ **Multi-Party Verification**: DAOs and institutions can verify and recognize credentials
- 🔒 **Immutable Records**: All credentials stored on-chain with optional expiration
- 📊 **Reputation System**: Track issuer performance with automatic reputation scoring
- 🏷️ **Skill Tagging**: Tag credentials with relevant skills for easy discovery
- 🔐 **Credential Revocation**: Issuers can revoke invalid or fraudulent credentials

## 🚀 Quick Start

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Basic understanding of Clarity and Stacks blockchain

### Installation

```bash
git clone <your-repo-url>
cd Modular-Certification-Platform
clarinet check
```

## 📖 Usage Guide

### 1️⃣ Register as an Issuer

```clarity
(contract-call? .Modular-Certification-Platform register-issuer "University of Web3")
```

Returns: `(ok u1)` - Your issuer ID

### 2️⃣ Verify an Issuer (Owner Only)

```clarity
(contract-call? .Modular-Certification-Platform verify-issuer 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

### 3️⃣ Issue a Credential

```clarity
(contract-call? .Modular-Certification-Platform issue-credential
    'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG
    "Blockchain Development"
    "ipfs://QmX7Y8Z9..."
    (some u1000000)
    (list "solidity" "clarity" "smart-contracts")
)
```

**Parameters:**
- `holder`: Principal receiving the credential
- `credential-type`: Type of certification (32 chars max)
- `metadata-uri`: IPFS or HTTP link to credential details (256 chars max)
- `expires-at`: Optional block height for expiration
- `skill-tags`: List of up to 10 skill tags

### 4️⃣ Create a Degree

```clarity
(contract-call? .Modular-Certification-Platform create-degree
    "Web3 Development Degree"
    (list u1 u2 u3 u4 u5)
    "ipfs://QmDegree..."
)
```

**Parameters:**
- `degree-name`: Name of the degree (64 chars max)
- `credential-ids`: List of up to 50 credential IDs to stack
- `metadata-uri`: Link to degree metadata

### 5️⃣ Recognize a Degree (Issuers/DAOs)

```clarity
(contract-call? .Modular-Certification-Platform recognize-degree u1)
```

### 6️⃣ Verify a Credential

```clarity
(contract-call? .Modular-Certification-Platform verify-credential
    u1
    "Verified skills match industry standards"
)
```

### 7️⃣ Lock a Degree

```clarity
(contract-call? .Modular-Certification-Platform lock-degree u1)
```

Prevents further modifications to ensure degree integrity.

### 8️⃣ Revoke a Credential

```clarity
(contract-call? .Modular-Certification-Platform revoke-credential u1)
```

Only the original issuer can revoke their credentials.

## 🔍 Read-Only Functions

### Check Credential Details

```clarity
(contract-call? .Modular-Certification-Platform get-credential u1)
```

### Check Credential Validity

```clarity
(contract-call? .Modular-Certification-Platform is-credential-valid u1)
```

Returns `true` if credential is not revoked and not expired.

### Get Degree Information

```clarity
(contract-call? .Modular-Certification-Platform get-degree u1)
```

### Get Issuer Reputation

```clarity
(contract-call? .Modular-Certification-Platform get-issuer-reputation 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

### Check Verification Status

```clarity
(contract-call? .Modular-Certification-Platform get-verification u1 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

## 🏗️ Contract Architecture

### Data Structures

- **Issuers**: Registered credential issuers with verification status
- **Credentials**: Individual micro-certificates with metadata
- **Degrees**: Stacked collections of credentials
- **Verifications**: Multi-party verification records
- **Reputation**: Automatic issuer reputation scoring

### Error Codes

| Code | Error | Description |
|------|-------|-------------|
| u100 | `err-owner-only` | Action requires contract owner |
| u101 | `err-not-found` | Resource not found |
| u102 | `err-already-exists` | Resource already exists |
| u103 | `err-unauthorized` | Caller not authorized |
| u104 | `err-invalid-credential` | Credential data invalid |
| u105 | `err-credential-expired` | Credential has expired |
| u106 | `err-not-issuer` | Caller is not registered issuer |
| u107 | `err-degree-locked` | Degree is locked from changes |
| u108 | `err-invalid-params` | Invalid function parameters |

## 🎯 Use Cases

### 🎓 Educational Institutions
- Issue course completion certificates
- Verify student achievements
- Recognize stacked degrees from multiple sources

### 🏢 Professional Organizations
- Certify professional skills and competencies
- Build verifiable career portfolios
- Cross-verify credentials from multiple issuers

### 🌐 DAOs & Web3 Communities
- Recognize community contributions
- Create decentralized credential standards
- Build reputation systems for members

### 💼 Employers
- Verify candidate credentials instantly
- Trust multi-verified qualifications
- Reduce credential fraud

## 🧪 Testing

Run the test suite:

```bash
clarinet test
```

Check for syntax errors:

```bash
clarinet check
```

## 🛡️ Security Considerations

- ✅ Only credential issuers can issue and revoke their own credentials
- ✅ Degree holders control their degree composition and locking
- ✅ Reputation automatically adjusts based on revocation rates
- ✅ Contract owner controls issuer verification
- ✅ Expired credentials automatically marked as invalid

## 🤝 Contributing

Contributions welcome! Please ensure all tests pass and follow Clarity best practices.

## 📄 License

MIT License

## 🔗 Links

- [Stacks Documentation](https://docs.stacks.co/)
- [Clarity Language Reference](https://docs.stacks.co/clarity/)
- [Clarinet Documentation](https://github.com/hirosystems/clarinet)

---

Built with ❤️ on the Stacks blockchain
