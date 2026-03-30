<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Booking update</title>
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
                            <img src="{{ asset('storage/logo/logo_light.png') }}" alt="Cribs Arena" style="height: 65px; display: block;" />
                        </td>
                    </tr>

                    <!-- Content -->
                    <tr>
                        <td style="padding: 40px;">
                            <p style="margin: 0 0 16px 0; font-size: 15px; color: #24292e;">Hi
                                {{ $recipientType === 'agent' ? $bookingData['agentName'] : $bookingData['userName'] }},
                            </p>

                            @if($status === 'rescheduled')
                                <p style="margin: 0 0 8px 0; font-size: 15px; color: #586069;">
                                    Your inspection booking has been rescheduled.
                                </p>
                            @elseif($status === 'completed')
                                <p style="margin: 0 0 8px 0; font-size: 15px; color: #586069;">
                                    Your inspection has been completed.
                                </p>
                            @elseif($status === 'cancelled')
                                <p style="margin: 0 0 8px 0; font-size: 15px; color: #586069;">
                                    Your inspection booking has been cancelled.
                                </p>
                            @endif

                            <!-- Status Badge -->
                            <table cellpadding="0" cellspacing="0" style="margin: 0 0 24px 0;">
                                <tr>
                                    <td
                                        style="background-color: #f6f8fa; border: 1px solid #e1e4e8; border-radius: 3px; padding: 4px 12px;">
                                        <span
                                            style="font-size: 11px; font-weight: 600; color: #586069; text-transform: uppercase; letter-spacing: 0.5px;">
                                            @if($status === 'rescheduled')
                                                Rescheduled
                                            @elseif($status === 'completed')
                                                Completed
                                            @elseif($status === 'cancelled')
                                                Cancelled
                                            @endif
                                        </span>
                                    </td>
                                </tr>
                            </table>

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
                                            @if($recipientType === 'user')
                                                <tr>
                                                    <td style="padding: 8px 0; font-size: 13px; color: #586069;">Agent</td>
                                                    <td
                                                        style="padding: 8px 0; font-size: 13px; color: #24292e; text-align: right;">
                                                        {{ $bookingData['agentName'] }}</td>
                                                </tr>
                                            @else
                                                <tr>
                                                    <td style="padding: 8px 0; font-size: 13px; color: #586069;">Client</td>
                                                    <td
                                                        style="padding: 8px 0; font-size: 13px; color: #24292e; text-align: right;">
                                                        {{ $bookingData['userName'] }}</td>
                                                </tr>
                                            @endif
                                            <tr>
                                                <td style="padding: 8px 0; font-size: 13px; color: #586069;">Property
                                                </td>
                                                <td
                                                    style="padding: 8px 0; font-size: 13px; color: #24292e; text-align: right;">
                                                    {{ $bookingData['propertyTitle'] }}</td>
                                            </tr>
                                            <tr>
                                                <td colspan="2"
                                                    style="border-top: 1px solid #e1e4e8; padding-top: 12px;"></td>
                                            </tr>
                                            @if($status === 'rescheduled')
                                                <tr>
                                                    <td style="padding: 8px 0; font-size: 13px; color: #586069;">New date
                                                    </td>
                                                    <td
                                                        style="padding: 8px 0; font-size: 13px; color: #24292e; text-align: right; font-weight: 500;">
                                                        {{ $bookingData['newInspectionDate'] }}</td>
                                                </tr>
                                                <tr>
                                                    <td style="padding: 8px 0; font-size: 13px; color: #586069;">New time
                                                    </td>
                                                    <td
                                                        style="padding: 8px 0; font-size: 13px; color: #24292e; text-align: right; font-weight: 500;">
                                                        {{ $bookingData['newInspectionTime'] }}</td>
                                                </tr>
                                            @else
                                                <tr>
                                                    <td style="padding: 8px 0; font-size: 13px; color: #586069;">Date</td>
                                                    <td
                                                        style="padding: 8px 0; font-size: 13px; color: #24292e; text-align: right;">
                                                        {{ $bookingData['inspectionDate'] }}</td>
                                                </tr>
                                                <tr>
                                                    <td style="padding: 8px 0; font-size: 13px; color: #586069;">Time</td>
                                                    <td
                                                        style="padding: 8px 0; font-size: 13px; color: #24292e; text-align: right;">
                                                        {{ $bookingData['inspectionTime'] }}</td>
                                                </tr>
                                            @endif
                                        </table>
                                    </td>
                                </tr>
                            </table>

                            @if($status === 'rescheduled')
                                <p style="margin: 0 0 16px 0; font-size: 14px; color: #586069;">
                                    Please confirm your availability for the new schedule. If you have any concerns, contact
                                    us through the app.
                                </p>
                            @elseif($status === 'completed' && $recipientType === 'user')
                                <p style="margin: 0 0 16px 0; font-size: 14px; color: #586069;">
                                    We hope you found your perfect property. Please consider leaving a review for the agent.
                                </p>
                            @elseif($status === 'cancelled')
                                @if(isset($bookingData['cancellationReason']))
                                    <p style="margin: 0 0 16px 0; font-size: 14px; color: #586069;">
                                        Reason: {{ $bookingData['cancellationReason'] }}
                                    </p>
                                @endif
                                @if($recipientType === 'user')
                                    <p style="margin: 0 0 16px 0; font-size: 14px; color: #586069;">
                                        If applicable, your refund will be processed within 5-7 business days.
                                    </p>
                                @endif
                            @endif

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