# CredStack 🎓

> Decentralized Academic Credentials Platform on Stacks

CredStack is a blockchain-based platform that enables universities and educational institutions to issue tamper-proof academic credentials while giving graduates full control over their privacy and verification settings.

## 🌟 Features

### 🏛️ Institution Management
- Authorized institutions can issue official credentials
- Multi-signature verification system with institution keys
- Credential revocation capabilities for institutions

### 🔒 Privacy-First Design
- **Private by default** - Credentials are not publicly visible
- **Granular privacy controls** - Choose what information to share
- **Selective disclosure** - Show only relevant details to specific viewers
- **Student-controlled verification** - Approve or deny verification requests

### 🎯 Credential Types
- University degrees
- Professional certificates
- Training diplomas
- Custom credential types

### 👥 Peer Attestations
- Skills verification through peer networks
- 1-5 proficiency rating system
- Community-driven skill validation
- Attestation comments and feedback

### ✅ Verification System
- Employer/verifier credential requests
- Student approval workflow
- Cryptographic proof of authenticity
- Immutable verification history

## 🏗️ Architecture

CredStack is built on the Stacks blockchain, inheriting Bitcoin's security while enabling smart contract functionality through Clarity.

### Smart Contract Structure

```
CredStack Contract
├── Institution Registry
│   ├── Authorized institutions
│   ├── Admin management
│   └── Verification keys
├── Credential Management
│   ├── Credential issuance
│   ├── Privacy settings
│   └── Revocation system
├── Attestation System
│   ├── Peer skill verification
│   ├── Proficiency ratings
│   └── Community feedback
└── Verification Workflow
    ├── Verification requests
    ├── Approval process
    └── Access control
```

## 🚀 Getting Started

### Prerequisites
- Stacks blockchain node or access to Stacks API
- Clarity CLI for contract deployment
- Web3 wallet (Hiro Wallet recommended)

### Contract Deployment

1. **Deploy the contract:**
```bash
clarinet deploy --testnet
```

2. **Register an institution (contract owner only):**
```clarity
(contract-call? .credstack register-institution 
  "University of Example" 
  'SP1234...ADMIN 
  0x1234...VERIFICATION_KEY)
```

3. **Issue a credential (institution admin):**
```clarity
(contract-call? .credstack issue-credential
  'SP5678...STUDENT
  "degree"
  "Computer Science"
  "Bachelor of Science"
  none  ;; no expiry
  0xabcd...METADATA_HASH)
```

## 📋 Usage Examples

### For Institutions

**Issue a Master's Degree:**
```clarity
(contract-call? .credstack issue-credential
  'SP1A1A1A1A1A1A1A1A1A1A1A1A1A1A1A1A1A1A1A
  "degree"
  "Data Science"
  "Master of Science"
  (some u210240)  ;; expires at block 210240
  0x89abcdef...)
```

**Revoke a Credential:**
```clarity
(contract-call? .credstack revoke-credential u123)
```

### For Students

**Set Privacy Settings:**
```clarity
(contract-call? .credstack update-privacy-settings
  u123          ;; credential-id
  false         ;; not public
  (list 'SP2222...EMPLOYER 'SP3333...RECRUITER)  ;; allowed viewers
  true          ;; show grade
  true)         ;; show institution
```

**Respond to Verification Request:**
```clarity
(contract-call? .credstack respond-to-verification u456 true)
```

### For Employers/Verifiers

**Request Credential Verification:**
```clarity
(contract-call? .credstack request-verification
  'SP1A1A1A1A1A1A1A1A1A1A1A1A1A1A1A1A1A1A1A  ;; student
  u123)  ;; credential-id
```

**View Approved Credential:**
```clarity
(contract-call? .credstack get-credential u123 tx-sender)
```

### For Peers

**Add Skill Attestation:**
```clarity
(contract-call? .credstack add-skill-attestation
  u123                    ;; credential-id
  "JavaScript"            ;; skill
  u4                      ;; proficiency (1-5)
  "Excellent problem solver with JS")  ;; comments
```

## 🔍 Read-Only Functions

### Check Credential Validity
```clarity
(contract-call? .credstack verify-credential u123)
```

### Get Student's Credentials
```clarity
(contract-call? .credstack get-student-credentials 
  'SP1A1A1A1A1A1A1A1A1A1A1A1A1A1A1A1A1A1A1A)
```

### Get Institution Info
```clarity
(contract-call? .credstack get-institution u1)
```

## 🛡️ Security Features

- **Role-based access control** - Different permissions for owners, institutions, students
- **Privacy preservation** - Default private credentials with selective disclosure
- **Cryptographic verification** - Institution verification keys for authenticity
- **Immutable records** - Credentials stored permanently on blockchain
- **Revocation system** - Institutions can revoke credentials if needed

## 🎯 Use Cases

### For Universities
- Issue digital diplomas and certificates
- Reduce credential fraud
- Streamline verification processes
- Build institutional reputation on-chain

### For Students/Graduates
- Own and control academic credentials
- Share credentials selectively
- Build verified skill portfolios
- Prove qualifications globally

### for Employers
- Instantly verify candidate credentials
- Reduce hiring fraud
- Access skill attestations from peers
- Build trust in recruitment process

## 🛣️ Roadmap

- [ ] **V1.0** - Core credential issuance and verification
- [ ] **V1.1** - Batch operations and bulk imports
- [ ] **V1.2** - Credential templates and standards
- [ ] **V1.3** - Integration with existing student information systems
- [ ] **V2.0** - Cross-chain credential portability
- [ ] **V2.1** - AI-powered skill verification
- [ ] **V2.2** - Decentralized identity integration


### Development Setup
```bash
git clone https://github.com/your-org/credstack
cd credstack
clarinet install
clarinet test
```
