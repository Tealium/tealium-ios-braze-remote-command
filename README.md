# Braze Remote Commands

A [Braze](https://www.braze.com/docs/developer_guide/platform_integration_guides/ios/initial_sdk_setup/initial_sdk_setup/) integration with the [Tealium SDK](https://github.com/tealium/tealium-swift) that enables Braze API calls to be made through  Tealium's [track](https://docs.tealium.com/platforms/swift/track/) API.

## Getting Started

Clone this repo and execute the `pod install` command in the project directory. You can then run the sample app to get an idea of the functionality.

### Prerequisites

* Tealium IQ account
* Braze account 

### Installing

To include the remote command files in your own project, simply clone this repo and drag the files within the Sources folder into your project. 

Include the [Tealium Swift](https://docs.tealium.com/platforms/swift/install/) and [Braze](https://www.braze.com/docs/developer_guide/platform_integration_guides/ios/initial_sdk_setup/initial_sdk_setup/) frameworks in your project through your desired dependency manager.

Configure the Tealium IQ _Braze Mobile Remote Command_ tag, send [track](https://docs.tealium.com/platforms/swift/track/) calls with any applicable data and validate in your [Braze Dashboard](https://dashboard.braze.com/sign_in).

## License

Use of this software is subject to the terms and conditions of the license agreement contained in the file titled [License.txt](License.txt). Please read the license before downloading or using any of the files contained in this repository. By downloading or using any of these files, you are agreeing to be bound by and comply with the license agreement.

___

Copyright (C) 2012-2019, Tealium Inc.

