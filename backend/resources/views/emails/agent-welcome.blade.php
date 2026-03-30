<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome to the Cribs Agent Community</title>
</head>

<body
    style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif; background-color: #f6f8fa; line-height: 1.6;">
    <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f6f8fa; padding: 40px 0;">
        <tr>
            <td align="center">
                <table width="600" cellpadding="0" cellspacing="0"
                    style="background-color: #ffffff; border: 1px solid #e1e4e8; border-radius: 6px;">
                    <!-- Header -->
                    <tr>
                        <td style="padding: 32px 40px; border-bottom: 1px solid #e1e4e8;">
                            <img src="{{ asset('storage/logo/logo_light.png') }}" alt="Cribs Arena"
                                style="height: 55px; display: block;" />
                        </td>
                    </tr>

                    <!-- Content -->
                    <tr>
                        <td style="padding: 40px;">
                            <p style="margin: 0 0 16px 0; font-size: 15px; color: #24292e;">Hi {{ $agentName }},</p>

                            <p style="margin: 0 0 24px 0; font-size: 15px; color: #586069;">
                                Welcome to the Cribs Agent Community! We're thrilled to have you join our network of
                                top-tier property professionals.
                            </p>

                            <p style="margin: 0 0 16px 0; font-size: 15px; color: #586069;">
                                Your agent account is now verified. Here's what you can do right away:
                            </p>

                            <!-- Features List -->
                            <table width="100%" cellpadding="0" cellspacing="0" style="margin: 0 0 24px 0;">
                                <tr>
                                    <td style="padding: 8px 0;">
                                        <table cellpadding="0" cellspacing="0">
                                            <tr>
                                                <td style="padding-right: 12px; vertical-align: top;">
                                                    <div
                                                        style="width: 20px; height: 20px; background-color: #f0fdf4; border: 1px solid #86efac; border-radius: 50%; display: flex; align-items: center; justify-content: center;">
                                                        <span
                                                            style="color: #166534; font-size: 12px; line-height: 20px;">✓</span>
                                                    </div>
                                                </td>
                                                <td style="font-size: 14px; color: #586069;">List your properties to
                                                    reach thousands of potential tenants</td>
                                            </tr>
                                        </table>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="padding: 8px 0;">
                                        <table cellpadding="0" cellspacing="0">
                                            <tr>
                                                <td style="padding-right: 12px; vertical-align: top;">
                                                    <div
                                                        style="width: 20px; height: 20px; background-color: #f0fdf4; border: 1px solid #86efac; border-radius: 50%; display: flex; align-items: center; justify-content: center;">
                                                        <span
                                                            style="color: #166534; font-size: 12px; line-height: 20px;">✓</span>
                                                    </div>
                                                </td>
                                                <td style="font-size: 14px; color: #586069;">Manage inspection bookings
                                                    and leads efficiently</td>
                                            </tr>
                                        </table>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="padding: 8px 0;">
                                        <table cellpadding="0" cellspacing="0">
                                            <tr>
                                                <td style="padding-right: 12px; vertical-align: top;">
                                                    <div
                                                        style="width: 20px; height: 20px; background-color: #f0fdf4; border: 1px solid #86efac; border-radius: 50%; display: flex; align-items: center; justify-content: center;">
                                                        <span
                                                            style="color: #166534; font-size: 12px; line-height: 20px;">✓</span>
                                                    </div>
                                                </td>
                                                <td style="font-size: 14px; color: #586069;">Chat directly with
                                                    interested clients</td>
                                            </tr>
                                        </table>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="padding: 8px 0;">
                                        <table cellpadding="0" cellspacing="0">
                                            <tr>
                                                <td style="padding-right: 12px; vertical-align: top;">
                                                    <div
                                                        style="width: 20px; height: 20px; background-color: #f0fdf4; border: 1px solid #86efac; border-radius: 50%; display: flex; align-items: center; justify-content: center;">
                                                        <span
                                                            style="color: #166534; font-size: 12px; line-height: 20px;">✓</span>
                                                    </div>
                                                </td>
                                                <td style="font-size: 14px; color: #586069;">Monitor your performance
                                                    and earnings in real-time</td>
                                            </tr>
                                        </table>
                                    </td>
                                </tr>
                            </table>

                            <p style="margin: 0 0 16px 0; font-size: 14px; color: #586069;">
                                Tip: Make sure your profile is complete to build trust and attract more clients.
                            </p>

                            <p style="margin: 0; font-size: 14px; color: #586069;">
                                Happy Listing!<br>
                                The Cribs Arena team
                            </p>
                        </td>
                    </tr>

                    <!-- Footer -->
                    <tr>
                        <td style="padding: 24px 40px; border-top: 1px solid #e1e4e8; background-color: #f6f8fa;">
                            <p style="margin: 0; font-size: 12px; color: #6a737d; line-height: 1.5;">
                                Cribs Arena<br>
                                © {{ date('Y') }} All rights reserved.
                            </p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>

</html>