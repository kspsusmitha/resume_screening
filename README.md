# AI-Powered Resume Screening and Resume Building System

A comprehensive Flutter application designed to simplify recruitment workflows for organizations while enhancing job search and preparation experiences for candidates. This system features AI-powered resume screening, resume building, interview preparation, and video resume capabilities.

## Features

### For HR Managers
- **Multi-HR Portal**: Role-based access with secure authentication
- **Job Posting Management**: Create, edit, publish, and manage job postings
- **AI Resume Screening**: Automated resume analysis with match percentage and skill gap identification
- **Application Management**: View, categorize, and track candidate applications
- **Candidate Categorization**: Tag candidates as Freshers, Experienced, High-Potential, or Re-Evaluate

### For Candidates
- **Job Browsing**: Search and filter job openings by skills, experience, domain, and location
- **AI Resume Builder**: Create professional, ATS-friendly resumes with AI assistance
- **AI Interview Preparation**: Practice with domain-specific questions and receive AI feedback
- **Video Resume Creation**: Record and submit video introductions with AI-generated scripts
- **Application Tracking**: Track application status in real-time

## Technology Stack

- **Framework**: Flutter (Dart)
- **State Management**: Provider
- **AI Integration**: Google Gemini API (gemini-flash-lite-latest)
- **File Handling**: file_picker, path_provider
- **PDF Generation**: pdf, printing
- **Video Recording**: camera, video_player

## Project Structure

```
lib/
├── models/              # Data models (User, Job, Application, Resume, etc.)
├── services/            # AI service for Gemini API integration
├── providers/           # State management providers
├── screens/             # UI screens
│   ├── auth/           # Authentication screens
│   ├── hr/             # HR portal screens
│   └── candidate/       # Candidate portal screens
├── widgets/             # Reusable widgets
└── theme/               # App theme and styling
```

## Setup Instructions

1. **Install Dependencies**
   ```bash
   flutter pub get
   ```

2. **Configure API Key**
   The Gemini API key is already configured in `lib/services/ai_service.dart`:
   ```dart
   static const String _apiKey = 'AIzaSyChcxUCymMoKzf9ckJNJMRgw_oAlTPnYCs';
   static const String _modelName = 'gemini-flash-lite-latest';
   ```

3. **Run the Application**
   ```bash
   flutter run
   ```

## Current Implementation Status

✅ **Completed Features:**
- UI for all major features
- AI integration with Google Gemini API
- Resume screening with match percentage calculation
- Interview preparation with question generation and answer evaluation
- Resume builder with AI-generated summaries
- Video resume script generation
- Job posting and management
- Application tracking
- Role-based authentication (mock)

⚠️ **Pending Features (For Future Firebase Integration):**
- Database persistence (currently using in-memory state)
- Real authentication with Firebase Auth
- File storage for resumes and videos
- User profile management
- Analytics and reporting

## Usage

### For HR Managers
1. Select "HR Manager" role on the welcome screen
2. Login or register
3. Access dashboard to:
   - Post new jobs
   - Screen resumes using AI
   - Manage applications
   - Categorize candidates

### For Candidates
1. Select "Candidate" role on the welcome screen
2. Login or register
3. Browse available jobs
4. Use AI-powered features:
   - Build professional resumes
   - Prepare for interviews
   - Create video resumes
   - Apply to jobs

## AI Features

### Resume Screening
- Extracts candidate information from resumes
- Compares resumes with job descriptions
- Calculates match percentages
- Identifies missing skills
- Provides recommendations (SHORTLIST, REJECT, REVIEW)

### Interview Preparation
- Generates domain-specific interview questions
- Evaluates candidate answers
- Provides detailed feedback with strengths and improvements
- Calculates performance scores

### Resume Builder
- AI-generated professional summaries
- Grammar and spelling correction
- Impact-based bullet point suggestions
- ATS-friendly formatting

### Video Resume
- AI-generated professional scripts
- Structured presentation guidance
- Ready for camera integration

## Future Enhancements

- Firebase integration for data persistence
- Real-time notifications
- Advanced analytics dashboard
- Multi-language support
- Export resumes as PDF
- Video recording and processing
- Email notifications
- Advanced search and filtering

## Notes

- Currently uses mock authentication (no real database)
- File uploads are simulated (file paths stored, not actual content)
- Video recording UI is ready but requires camera integration
- All data is stored in memory and will be lost on app restart
- Firebase integration is planned for future releases

## License

This project is created for educational and development purposes.
