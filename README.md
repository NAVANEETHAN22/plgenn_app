# PlGenN - Payload Generation and Behavioral Validation Framework

PlGenN is a lightweight Android-based framework for web vulnerability testing. It combines rule-based payload generation, adaptive mutation, machine learning-based payload characterization, and runtime behavioral validation to assist security researchers and developers in evaluating web application security.

The framework focuses on generating diverse payloads while validating whether the generated inputs actually trigger vulnerability-relevant behavior during execution.

---

## Screenshots

### Home Screen

Place the first screenshot here:

```markdown
<img width="388" height="811" alt="1" src="https://github.com/user-attachments/assets/353e4d47-4c44-47d3-8e51-90eb44c1a5f7" />

```

This screen provides access to:

* Rule-Based Payload Generator
* Hybrid Payload Generator
* Payload Testing Module

### Hybrid Payload Generator

Place the second screenshot here:

```markdown
<img width="398" height="797" alt="2" src="https://github.com/user-attachments/assets/d2f1f524-6b3a-4af9-9e01-4c86d1e68796" />

```

This interface allows users to:

* Select a target URL
* Choose a vulnerability category
* Configure testing modes
* Generate payloads
* Perform behavioral validation

---

## Features

* Rule-based payload generation
* Hybrid payload generation with adaptive mutation
* Multi-class vulnerability support
* Runtime behavioral validation
* Lightweight Android deployment
* Payload diversity enhancement
* Vulnerability-oriented payload testing

---

## Supported Vulnerability Classes

* SQL Injection (SQLi)
* Cross-Site Scripting (XSS)
* Command Injection (CMD)
* Local File Inclusion (LFI)
* Path Traversal (PATH)
* Server-Side Request Forgery (SSRF)
* XML External Entity (XXE)
* Insecure Direct Object Reference (IDOR)
* GraphQL Injection (GQLi)
* Open Redirect (ORA)
* API Abuse (APIm)

---

## Framework Workflow

1. Generate seed payloads using predefined templates.
2. Apply adaptive mutation to increase payload diversity.
3. Characterize generated payloads using lightweight machine learning techniques.
4. Execute payloads against target endpoints.
5. Validate runtime behavior.
6. Generate vulnerability findings and testing reports.

---

## Technologies Used

* Java
* Android Studio
* TensorFlow Lite
* Material Design Components

---

## Research Background

PlGenN was developed as part of academic research on behavior-aware web vulnerability testing. The framework investigates whether runtime behavioral validation can provide stronger evidence of exploitability compared to classification-only approaches.

---
