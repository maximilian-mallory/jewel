# Introduction  

Project Emerald intends to serve the busy people of the world. It is not very often that we are available for ourselves, so why don't we design a tool that does it for us? No more tardiness due to poorly estimated commute times; More time spent on personal growth; Less time figuring out what to do with our day. In a world full of so many moving parts, why can’t we have someone, or something, take care of our time for us. After all, time is money, and it is up to you to determine how much you value both. 

# Objectives 

## Individual Learning Goals 

- ### Jeremy 

- ### Ellie 

- ### Ian 

During this project, I would like to develop my understanding of containerization by using Firebase and Docker. I also hope to learn front end development by using Android and IOS APIs in the development of this project. 

- ### Alex 

During this project, I would like to develop my knowledge of Flutter and Dart as well as strength my knowledge of Python, Bash, and JSON. I also hope to be able to continue learning about containerization with things such as Docker. As for the completion status of this project, I hope that we are able to have something that can correctly use the Google and Outlook connections to correctly combine calendars. 

- ### Max 

During this project, my primary goal is to gain more knowledge in the orchestration of CI/CD pipelines and developing software systems. I would also like to further my experience leading projects, especially with a group of developers who will be using most of the project technologies for the very first time. This will assess my current skills as a teacher and leader, while also creating a benchmark that serves as our final product.

## Group Learning Goals 
TODO:

## Intended Project Outcome 

### The MVP

Our minimum viable product will:
- Merge two or more calendars
- Use the Google Calendar API to pull event data from a user's Google account
- Allow the user to calculate commute time and distance using the Google Maps API
- Allow the user to provide event location data to automatically do the commute time calculations
- Allow the user to color code and stylize their application for additional accessibility
- Provide manual goal input to fill gaps in daily calendar
- Provide the user the opportunity to decide when their day starts and ends
- Provide a reward system for goal progress and goal completion
- Track all goals, completed or not, and their progress
- Allow user input for how a goal was progressed, like a journal entry for each task
- Implement Google Auth with Firebase Cloud Firestore and the Google Auth Gmail API
- Be available in a browser, as a native Mac or Windows app, and as a native iOS or Android app
- Be containerized via Docker
- Be tested and deployed automatically using a CI/CD pipeline
- Be hosted externally

### Nice to Have

Features we would like to implement that are not required for the MVP:
- Microsoft Graph API implementation (Outlook calendar merge, Teams notifications)
- AWS AI implementation for natural language output of daily calendars (GenAI, Polly)
- Goal recommendations and suggestions

# User Stories 

TODO: Provide user requirements 

    1. User Types (Student, User with heightened accessibility needs, developer) 

    2. User Stories (As a [usertype], I want to [action or feature] to achieve [result]) 

- As a user with heightened accessibility needs, I want to create events on a calendar to remind me of the event 
- As a user with heightened accessibility needs, I want to create a group of events that has a group of colors to organize my events  
- As a user with heightened accessibility needs, I want to manually select a color for an event to make a reminder of its importance 
- As a developer, I want to learn the Flutter framework and Dart programming language so that I can contribute successfully to the source code.  
- As a developer, I want to test my app in an Android emulator, so I know what my program looks like on a mobile device. 
- As a developer, I want to containerize my application so it can run in a hosted environment without conflict. 
- As a developer, I want to automate my testing within the CI/CD pipeline so I can deploy seamlessly when my code merges. 
- As a student, I want to use Google maps to calculate my commute time between responsibilities, so I am not late because of the distance between buildings on campus. 
- As any user, I want to be able to login to my Google calendar the same way I would log into the actual Google calendar. 
       
# System Architecture 
TODO: Architecture diagram and DFD 

## Tech Stack 

- Programming Languages and Frameworks 
    - Flutter 
    - Dart 
    - Python (for AWS scripts) 
    - Bash? 
    - JSON (if you want to count this as a language) 

- Database Technologies 
    - MongoDB 
    - Firebase Cloud FireStore (for Google data) 
    - Amazon S3

# Data Models 

TODO: Provide examples of objects that may require schema. Things like user models, user settings, and static formatting may require schema. 

#### User
{
    firstname: string,
    lastname: string,
    email: string,
    themeid: long,
    id: string,
}

#### Theme
{
    font: string,
    dark: bool,
    colorStyle: string,
}

# Algorithms and Data Structures 

TODO: Describe how algorithms may be used in any of the many features this program will have. Graphs are likely, but other ADTs may be useful to us in this application. It is appropriate to include things we will use that are built into AWS. 

## Calendar Merge

In an effort to provide two or more calendars to be combined, we will want an algorithm that merges and sorts two json blobs. This merge would allow for one custom calendar object to be created from two or more. The algorithm should also determine if there are merge conflicts when creating events. Specifically, a user should not be able to create a calendar event with provider A that overlaps with provider B. This should also factor in the commute time, as the user will create that data upon initializing the calendar event.

## Goal Proposer

This does not need to be an AI tool. By giving goals weight and implementing a Graph ADT, the program could take the available time between tasks and create appropriate calendar events specific to the goal with the highest priority or what we can refer to as "lowest cost for highest reward". If a student has 30 minutes on campus where they can fill the gap with progressing a goal, we will want to ensure that the goal is adequate. So, if I am a user and I want to do my 15 minute daily stretching routine, I should be able to tell my goal that I only want to progress that goal at home and not another location. 

# APIs and External Services 

## APIs 

- Google APIs 
    - Firebase CLI 
    - Google Auth API 
    - Google Maps API 
    - Google Styles (UI) 

- Microsoft APIs 
    - Microsoft Graph API 

- Other 
    - Mongoose for MongoDB 

## External Services 

- AWS
    - AWS CDK
    - EC2
    - S3
    - Route53
    - KMS
    - Polly
    - GenAI
- Google
    - Cloud FireStore

# Security Measures 

## Security in the Cloud

It is unlikely that we will be putting this application behind any kind of Private Cloud. We may want to implement some access control, but DNS routing will be the bare minimum. We will continue to identify risks as we begin cloud development

## Auth Handoff

All of the user authorization will be handled by third party providers. We will not be storing any sensitive information. By using these well built and predefined services, we can remove much of our own security responsibility

## Key Managment

In addition to handing off the authorization, we can store our API keys in KMS. We will want this set up as soon as possible so we don't have to worry about storing API keys in the remote source code repository by accident... It happens, but we can prevent it early.
 
# Testing Strategy 

All tested will be automated with the CI/CD pipeline. When a developer deploys their code, a job will run that implements the following tests:

## Unit testing

- Themes
    - Tested for expected hex color values
    - Tested for expected names
    - Tested for toggle function between light and dark
    - Tested for appropriate API responses if web imports or third party styles are used
- User
    - Integration testing with Themes
        - Does the theme persist on reload?
        - Can the user save or favorite themes?
        - Can the user create and store their own theme?
    - User persistence with Third-Party Auth ID matching

## Functional Testing

- Can we CRUD a calendar event?
- Can we force an event merge conflict?
- Can we give the Maps API bogus information?
- Can we give the Maps API real information?
- Can we login and logout?
- Can we ... ?

## Integration Testing
TODO: complete
 
# Project Timeline 

Our projected timeline begins with Sprint 1 and ends one full week before the project deadline. To provide a crisp and bug-free product, our project will not be allowed modifications the week prior to its submission. This will also allow members to focus on studying for their final exams. 

We will attempt to resolve the Minimum Viable Product by Thanksgiving break. This will leave about 2 weeks for adding fun stuff or getting around to things that were too complicated or unnecessary for our overall goal. AWS AI tools like Polly and GenAI fall into this category. 

# Appendices 
TODO: If any information is left over, insert here. 

 