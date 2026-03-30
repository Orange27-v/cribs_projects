<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Booking confirmed</title>
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
                                style="height: 65px; display: block;" />
                        </td>
                    </tr>

                    <!-- Content -->
                    <tr>
                        <td style="padding: 40px;">
                            <p style="margin: 0 0 16px 0; font-size: 15px; color: #24292e;">Hi
                                {{ $bookingData['userName'] }},
                            </p>

                            <p style="margin: 0 0 24px 0; font-size: 15px; color: #586069;">
                                Your inspection booking has been confirmed.
                            </p>

                            <!-- Booking Details -->
                            <table width="100%" cellpadding="0" cellspacing="0"
                                style="margin: 0 0 24px 0; background-color: #f6f8fa; border: 1px solid #e1e4e8; border-radius: 6px;">
                                <tr>
                                    <td style="padding: 20px;">
                                        <table width="100%" cellpadding="0" cellspacing="0">
                                            <tr>
                                                <td style="padding: 8px 0; font-size: 13px; color: #586069;">Booking ID
                                                </td>
                                                <td
                                                    style="padding: 8px 0; font-size: 13px; color: #24292e; text-align: right; font-weight: 500;">
                                                    #{{ $bookingData['bookingId'] }}</td>
                                            </tr>
                                            <tr>
                                                <td colspan="2"
                                                    style="border-top: 1px solid #e1e4e8; padding-top: 12px;"></td>
                                            </tr>
                                            <tr>
                                                <td style="padding: 8px 0; font-size: 13px; color: #586069;">Agent</td>
                                                <td
                                                    style="padding: 8px 0; font-size: 13px; color: #24292e; text-align: right;">
                                                    {{ $bookingData['agentName'] }}
                                                </td>
                                            </tr>
                                            <tr>
                                                <td style="padding: 8px 0; font-size: 13px; color: #586069;">Property
                                                </td>
                                                <td
                                                    style="padding: 8px 0; font-size: 13px; color: #24292e; text-align: right;">
                                                    {{ $bookingData['propertyTitle'] }}
                                                </td>
                                            </tr>
                                            <tr>
                                                <td style="padding: 8px 0; font-size: 13px; color: #586069;">Location
                                                </td>
                                                <td
                                                    style="padding: 8px 0; font-size: 13px; color: #24292e; text-align: right;">
                                                    {{ $bookingData['propertyLocation'] }}
                                                </td>
                                            </tr>
                                            <tr>
                                                <td colspan="2"
                                                    style="border-top: 1px solid #e1e4e8; padding-top: 12px;"></td>
                                            </tr>
                                            <tr>
                                                <td style="padding: 8px 0; font-size: 13px; color: #586069;">Date</td>
                                                <td
                                                    style="padding: 8px 0; font-size: 13px; color: #24292e; text-align: right; font-weight: 500;">
                                                    {{ $bookingData['inspectionDate'] }}
                                                </td>
                                            </tr>
                                            <tr>
                                                <td style="padding: 8px 0; font-size: 13px; color: #586069;">Time</td>
                                                <td
                                                    style="padding: 8px 0; font-size: 13px; color: #24292e; text-align: right; font-weight: 500;">
                                                    {{ $bookingData['inspectionTime'] }}
                                                </td>
                                            </tr>
                                            <tr>
                                                <td style="padding: 8px 0; font-size: 13px; color: #586069;">Meeting
                                                    point</td>
                                                <td
                                                    style="padding: 8px 0; font-size: 13px; color: #24292e; text-align: right;">
                                                    {{ $bookingData['meetingPoint'] ?? 'Property location' }}
                                                </td>
                                            </tr>
                                            <tr>
                                                <td colspan="2"
                                                    style="border-top: 1px solid #e1e4e8; padding-top: 12px;"></td>
                                            </tr>
                                            <tr>
                                                <td style="padding: 8px 0; font-size: 13px; color: #586069;">Amount paid
                                                </td>
                                                <td
                                                    style="padding: 8px 0; font-size: 13px; color: #24292e; text-align: right; font-weight: 600;">
                                                    ₦{{ number_format($bookingData['amount'], 2) }}</td>
                                            </tr>
                                        </table>
                                    </td>
                                </tr>
                            </table>

                            <p style="margin: 0 0 16px 0; font-size: 14px; color: #586069;">
                                Please arrive 5-10 minutes early. The agent will contact you if there are any changes.
                            </p>

                            <p style="margin: 0; font-size: 14px; color: #586069;">
                                Thanks,<br>
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